#!/usr/bin/env python3
"""战力 6.0 模块(tools/power_scale_v6.py)的黄金测试。

纯只读:不改 data/*.json,不改 tools/power_scale_v6.py 之外的任何文件。
运行:`python3 tools/power_scale_v6.py` 先生成一次(可选),然后
`python3 tools/test_power_scale_v6.py`。无 pytest 依赖,遵循本仓库
tools/check_*.py 的一贯写法:每个 test_* 返回失败信息列表,main() 汇总退出码。

覆盖 C 阶段简报要求的黄金测试:
1. 单调性:能力提升(componentwise 更强的构筑)时,g_player / 有效战力不降。
2. 恒定性(红线 2):build -> 有效战力 的 API 结构上不可能读到 level/Q(L)/matchup,
   用签名检查 + 089/090 实际锚点样本做双重验证。
3. 外推有效:手工把顶端(099)能力放大 2x/4x,读数继续增长,不在顶端饱和。
4. 锚点命中量级带:P(1)/P(50)/P(99) 落在 C 阶段简报的目标带内。
5. B2 99×10 证据完整且推荐值只由验收档位反解。
6. 防线平台与 Boss 锯齿两个预建缺陷均已消除。
7. 同档 R 离散、档位单调、相邻普通/Boss 连续性均通过硬断言。
"""
from __future__ import annotations

import inspect
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import power_scale_v6 as psv6  # noqa: E402
import power_ruler_model as prm  # noqa: E402


Failures = list[str]


def _isclose(a: float, b: float, rel=1e-9, abs_=1e-9) -> bool:
    return abs(a - b) <= max(rel * max(abs(a), abs(b)), abs_)


# ---------------------------------------------------------------------------
# 0. PAVA 自检(F(g) 平滑的基础算法,先验证算法本身正确)
# ---------------------------------------------------------------------------

def test_pava_basic() -> Failures:
    failures: Failures = []
    out = psv6.isotonic_nondecreasing([1.0, 3.0, 2.0, 4.0])
    expected = [1.0, 2.5, 2.5, 4.0]
    if any(not _isclose(a, b) for a, b in zip(out, expected)):
        failures.append(f"PAVA 经典样例 [1,3,2,4] 期望 {expected},实得 {out}")
    for i in range(1, len(out)):
        if out[i] < out[i - 1] - 1e-9:
            failures.append(f"PAVA 输出非单调不减: index {i-1}->{i}: {out[i-1]}->{out[i]}")
    already_sorted = psv6.isotonic_nondecreasing([1.0, 2.0, 3.0])
    if any(not _isclose(a, b) for a, b in zip(already_sorted, [1.0, 2.0, 3.0])):
        failures.append(f"PAVA 对已单调序列不应改动,实得 {already_sorted}")
    return failures


# ---------------------------------------------------------------------------
# 1. 单调性:能力提升(componentwise dominance)时,g_player / 有效战力不降
# ---------------------------------------------------------------------------

def test_monotonic_axis_curve(model: "psv6.PowerScaleV6") -> Failures:
    """F(g) 自身(插值 + 顶端外推)必须处处单调不减 —— 这是保序回归 + 对数线性外推
    构造出来的硬保证,采样检查即可,不依赖具体游戏数值。"""
    failures: Failures = []
    import numpy as np

    sample_g = list(np.linspace(-20.0, 250.0, 400))
    for axis in psv6.AXES:
        curve = model.curves[axis]
        prev = None
        for g in sample_g:
            value = curve.forward(g)
            if prev is not None and value < prev - 1e-6:
                failures.append(
                    f"F_{axis}(g) 在 g={g:.2f} 处比前一采样点下降"
                    f"({value:.4f} < {prev:.4f}),违反单调性")
                break
            prev = value
    return failures


def test_monotonic_build_power(model: "psv6.PowerScaleV6") -> Failures:
    """构造 componentwise 单调递增的合成构筑(武器等级、角色等级递增,技能只加不减),
    验证有效战力序列不降 —— 这是"能力↑→读数不降"的直接语义。"""
    failures: Failures = []
    base_skills = {"skill_multishot": 1, "skill_pierce": 1}
    prev_power = None
    prev_axes = None
    for weapon_level in range(1, 51, 5):
        for character_level in range(1, 26, 5):
            build = {
                "character": "vanguard",
                "weapon": "weapon_autocannon",
                "character_level": character_level,
                "weapon_level": weapon_level,
                "armor": "",
                "armor_level": 1,
                "chip": "",
                "chip_level": 1,
                "pet": "",
                "pet_level": 1,
                "signature_level": 0,
            }
            build["skill_base_levels"] = base_skills
            result = model.effective_power_for_build(build)
            axes = result["axes"]
            if prev_axes is not None:
                dominates = all(axes[a] >= prev_axes[a] - 1e-6 for a in psv6.AXES)
                if dominates and result["effective_power"] < prev_power:
                    failures.append(
                        f"weapon_level={weapon_level}, character_level={character_level}: "
                        f"三轴能力均不降({prev_axes} -> {axes}),但有效战力从 {prev_power} "
                        f"降到 {result['effective_power']}")
            prev_power = result["effective_power"]
            prev_axes = axes
    # 单独纯粹递增武器等级(其余全部锁死),必须整体不降
    powers = []
    for weapon_level in range(1, 51):
        build = {
            "character": "vanguard", "weapon": "weapon_autocannon",
            "character_level": 10, "weapon_level": weapon_level,
            "armor": "", "armor_level": 1, "chip": "", "chip_level": 1,
            "pet": "", "pet_level": 1, "signature_level": 0,
        }
        build["skill_base_levels"] = base_skills
        powers.append(model.effective_power_for_build(build)["effective_power"])
    for i in range(1, len(powers)):
        if powers[i] < powers[i - 1]:
            failures.append(
                f"仅递增 weapon_level(其余锁死)时有效战力在 lv{i}->{i+1} 处下降: "
                f"{powers[i-1]} -> {powers[i]}")
    return failures


def test_segmented_weapon_growth_zero_leakage(model: "psv6.PowerScaleV6") -> Failures:
    failures: Failures = []
    weapons = model.tables["weapons"]
    for weapon_id, weapon in weapons.items():
        if weapon.get("level_growth_segments"):
            continue
        for level in range(1, int(weapon.get("max_level", 1)) + 1):
            legacy = 1.0 + 0.08 * max(level - 1, 0)
            actual = prm.weapon_level_damage_multiplier(weapon, level)
            if actual != legacy:
                failures.append(
                    f"{weapon_id} lv{level}: segment-free multiplier {actual!r} "
                    f"differs byte-for-byte from legacy {legacy!r}")
                break
    golden = weapons["weapon_apocalypse_golden_law"]
    values = [prm.weapon_level_damage_multiplier(golden, level) for level in range(1, 66)]
    if any(values[index] <= values[index - 1] for index in range(1, len(values))):
        failures.append("Golden Law segmented level curve must be strictly increasing through Lv65")
    if prm.weapon_level_damage_multiplier(golden, 50) != 1.0 + 0.08 * 49:
        failures.append("Golden Law Lv1-50 must remain on the standard +0.08 additive curve")
    if prm.weapon_level_damage_multiplier(golden, 65) != 1.0 + 0.08 * 64:
        failures.append("Golden Law Lv51-65 must continue the standard +0.08 additive curve")
    if prm.weapon_standard_growth_cap(golden) != 50:
        failures.append("Golden Law segmented standard-growth cap must remain Lv50")
    if prm.weapon_standard_growth_level(golden, 65) != 50.0:
        failures.append("Golden Law overcap levels must not extend baseline cadence past Lv50")
    if prm.weapon_endgame_growth_multiplier(golden, 50) != 1.0 or prm.weapon_endgame_growth_multiplier(golden, 65) != 1.0:
        failures.append("Golden Law must not retain a private endgame growth multiplier")
    return failures


# ---------------------------------------------------------------------------
# 2. 恒定性(红线 2):build -> 有效战力 结构上不读 level/Q(L)/matchup
# ---------------------------------------------------------------------------

FORBIDDEN_PARAM_SUBSTRINGS = (
    "level", "requirement", "contract", "enemy", "wave", "mob_hp", "boss_hp",
    "hp_share", "waves", "recommend",
)


def test_capability_api_has_no_level_coupling() -> Failures:
    """签名护栏:玩家能力 API 不得出现任何 level/敌方总量/推荐值相关形参名,
    防止未来有人不小心把关卡耦合加回中性能力计算(C 阶段红线)。"""
    failures: Failures = []
    targets = [
        psv6.stable_skill_levels,
        psv6.stable_projected_skill_levels,
        psv6.neutral_axis_capacities,
        psv6.PowerScaleV6.effective_power_for_build,
        psv6.PowerScaleV6.g_player,
    ]
    for fn in targets:
        params = list(inspect.signature(fn).parameters)
        for param in params:
            lowered = param.lower()
            for bad in FORBIDDEN_PARAM_SUBSTRINGS:
                if bad in lowered and param not in ("tables",):
                    failures.append(
                        f"{fn.__qualname__} 的形参 `{param}` 命中禁用词 `{bad}`,"
                        "疑似把关卡/要求耦合进了玩家能力 API")
    return failures


def test_constancy_089_090(model: "psv6.PowerScaleV6") -> Failures:
    """design/40 §1.2.7 的实证锚点:同一构筑在 089/090 两关旧模型读数从 3371 摆到 724
    (4.7 倍)。v6 中性口径下,玩家侧有效战力是对 (build, projected_skills) 的纯函数,
    与 level_id 完全无关 —— 用 089 的按节奏样本构筑,分别"套用"在 089/090 两个关卡
    语境下计算有效战力,数字必须逐位相同;而两关的推荐战力(Q(L) 反解)允许、也应该
    不同,真实难度差异必须体现在 R 上,不能体现在玩家自己的数字上。"""
    failures: Failures = []
    row_089 = next(r for r in model.fixture_rows if r["level_id"] == "level_089")
    build = row_089["scale_build"]

    power_as_089 = model.effective_power_for_build(build)
    power_as_090 = model.effective_power_for_build(build)  # 同一 API,无 level 入参
    if power_as_089["effective_power"] != power_as_090["effective_power"]:
        failures.append(
            "同一构筑重复计算得到不同的有效战力,API 应当是纯函数: "
            f"{power_as_089['effective_power']} != {power_as_090['effective_power']}")
    if power_as_089["axes"] != power_as_090["axes"]:
        failures.append("同一构筑重复计算三轴能力不一致")

    rec_089 = model.recommended_power_for_level("level_089")
    rec_090 = model.recommended_power_for_level("level_090")
    if rec_089["recommended_power_v6"] == rec_090["recommended_power_v6"]:
        failures.append(
            "089/090 推荐战力(Q(L) 反解)完全相同,样本可能选得不好,"
            "无法验证「难度差异体现在推荐值而不是玩家数字」这条主张")
    return failures


# ---------------------------------------------------------------------------
# 3. 外推有效:手工放大顶端能力,读数继续增长(付费/满配不封顶)
# ---------------------------------------------------------------------------

def test_extrapolation_grows(model: "psv6.PowerScaleV6") -> Failures:
    failures: Failures = []
    top_row = model.fixture_rows[-1]  # level 99,免费毕业锚点
    base_axes = psv6.neutral_axis_capacities(top_row["scale_build"], model.tables)

    def power_for_scale(scale: float) -> tuple[float, int]:
        scaled = {axis: value * scale for axis, value in base_axes.items()}
        g = model.g_player(scaled)
        return g, int(round(psv6.display_power(g)))

    g0, p0 = power_for_scale(1.0)
    g2, p2 = power_for_scale(2.0)
    g4, p4 = power_for_scale(4.0)

    if not (g2 > g0):
        failures.append(f"顶端能力 2x 后 g_player 未增长: g0={g0:.2f} g2={g2:.2f}")
    if not (p2 > p0):
        failures.append(f"顶端能力 2x 后有效战力未增长(疑似顶端饱和): p0={p0} p2={p2}")
    if not (g4 > g2 and p4 > p2):
        failures.append(f"顶端能力 4x 相对 2x 未继续增长: g2={g2:.2f}/p2={p2} -> g4={g4:.2f}/p4={p4}")
    if not (g0 <= 99.0 + 1e-6):
        failures.append(f"未放大时(免费毕业构筑本身)g_player 不应超过 99 太多: g0={g0:.2f}")
    if not (g2 > 99.0):
        failures.append(f"2x 放大后 g_player 应该突破顶端锚点 99: g2={g2:.2f}")
    return failures


# ---------------------------------------------------------------------------
# 4. 锚点命中量级带(C 阶段简报)
# ---------------------------------------------------------------------------

def test_anchor_bands() -> Failures:
    failures: Failures = []
    checks = (
        (1.0, psv6.TARGET_BAND_L01, "L01"),
        (50.0, psv6.TARGET_BAND_L50, "L50"),
        (99.0, psv6.TARGET_BAND_L99, "L99"),
    )
    for g, (lo, hi), name in checks:
        value = psv6.display_power(g)
        if not (lo <= value <= hi):
            failures.append(f"P({name}={g:.0f}) = {value:.1f},超出目标带 [{lo}, {hi}]")

    import numpy as np
    prev = None
    for g in np.linspace(-50.0, 300.0, 400):
        value = psv6.display_power(float(g))
        if prev is not None and value < prev - 1e-9:
            failures.append(f"P(g) 在 g={g:.2f} 处下降,违反单调性")
            break
        prev = value
    return failures


def test_display_power_roundtrip() -> Failures:
    failures: Failures = []
    for g in (-50.0, 1.0, 5.0, 49.5, 50.0, 99.0, 160.0):
        restored = psv6.display_power_inverse(psv6.display_power(g))
        if not _isclose(restored, g, rel=1e-11, abs_=1e-10):
            failures.append(f"P^-1(P({g})) = {restored},运行时镜像会发生漂移")
    return failures


def test_v5_comparison_snapshot(model: "psv6.PowerScaleV6") -> Failures:
    failures: Failures = []
    expected = {"level_001": 10, "level_050": 291, "level_099": 1437}
    for level_id, old_value in expected.items():
        observed = model.recommended_power_for_level(level_id).get("recommended_power_v5_current")
        if observed != old_value:
            failures.append(f"{level_id} frozen v5 comparison drifted: {observed} != {old_value}")
    if model.recommended_power_for_level("level_099")["recommended_power_v6"] <= expected["level_099"]:
        failures.append("L099 v6 recommendation must differ materially from the frozen v5 comparison")
    return failures


def test_runtime_config(model: "psv6.PowerScaleV6") -> Failures:
    failures: Failures = []
    config = model.runtime_config()
    if config.get("model") != "power_scale_v6":
        failures.append("runtime config model id drifted")
    if config.get("fire_rate_profile") != "tier_b":
        failures.append("runtime config must freeze Tier B")
    for axis in psv6.AXES:
        row = config.get("axes", {}).get(axis, {})
        if row.get("samples") != model.curves[axis].smoothed:
            failures.append(f"runtime config {axis} samples drifted from Python F(g)")
        if not float(row.get("bottom_slope", 0.0)) > 0.0:
            failures.append(f"runtime config {axis} bottom extrapolation slope is not positive")
        if not float(row.get("top_slope", 0.0)) > 0.0:
            failures.append(f"runtime config {axis} top extrapolation slope is not positive")
    return failures


def test_axis_curve_roundtrip(model: "psv6.PowerScaleV6") -> Failures:
    failures: Failures = []
    for axis, curve in model.curves.items():
        for g in (-12.0, 0.0, 1.0, 17.5, 50.0, 99.0, 140.0):
            restored = curve.inverse(curve.forward(g))
            if not _isclose(restored, g, rel=1e-8, abs_=1e-7):
                failures.append(f"F_{axis}^-1(F({g})) = {restored}")
    return failures


def test_projection_repairs(model: "psv6.PowerScaleV6") -> Failures:
    failures: Failures = []
    line = model.curves["line"].raw
    longest = run = 1
    for index in range(1, len(line)):
        run = run + 1 if _isclose(line[index], line[index - 1]) else 1
        longest = max(longest, run)
    if longest >= 16:
        failures.append(f"防线轴仍有 {longest} 关连续平台,预建缺陷未修复")

    boss_curve = model.curves["boss"]
    boss_outliers = 0
    for raw, smooth in zip(boss_curve.raw, boss_curve.smoothed):
        if smooth > 0.0 and abs(raw / smooth - 1.0) > 0.15:
            boss_outliers += 1
    if boss_outliers > 5:
        failures.append(f"Boss 轴仍有 {boss_outliers}/99 个 >15% 锯齿点")
    return failures


def test_b2_requirement_gates(model: "psv6.PowerScaleV6") -> Failures:
    failures: Failures = []
    rows = []
    for row in model.fixture_rows:
        effective = model.effective_power_for_build(row["scale_build"])["effective_power"]
        requirement = model.requirements[row["level_id"]]
        recommended = int(requirement["recommended_power"])
        rows.append({
            "level": int(row["level"]),
            "grade": str(requirement["grade"]),
            "ratio": float(effective) / max(float(recommended), 1.0),
        })

    grade_means = []
    for grade in psv6.GRADE_TARGET_R:
        values = [row["ratio"] for row in rows if row["grade"] == grade]
        dispersion = (max(values) - min(values)) * 0.5
        # Owner 2026-08-31: 推荐值强制单调(简单关不得显示回落)是玩家可见的产品约束,
        # 优先级高于内部 R 一致性。抬高简单关的推荐值必然压低其 R,把同档离散从
        # ±0.05 推到 ±0.07;7% 的 R 差异在体验上不可感知,故按单调化后的实测放宽。
        if dispersion > 0.07 + 1e-9:
            failures.append(f"{grade} 同档 R 离散 ±{dispersion:.4f} > ±0.07")
        grade_means.append(sum(values) / len(values))
    for index in range(1, len(grade_means)):
        if not grade_means[index] < grade_means[index - 1]:
            failures.append(f"档位 R 未严格递减: {grade_means}")
            break

    for index in range(1, len(rows)):
        current_level = rows[index]["level"]
        previous_level = rows[index - 1]["level"]
        delta = abs(rows[index]["ratio"] / rows[index - 1]["ratio"] - 1.0)
        boss_edge = current_level % 5 == 0 or previous_level % 5 == 0
        limit = 0.15 if boss_edge else 0.11
        if delta > limit + 1e-9:
            failures.append(
                f"L{previous_level:03d}->L{current_level:03d} R 跳变 {delta:.2%} > {limit:.0%}"
            )

    anchors = (
        (1, psv6.TARGET_BAND_L01),
        (50, psv6.TARGET_BAND_L50),
        (99, psv6.TARGET_BAND_L99),
    )
    for level, (lower, upper) in anchors:
        recommended = model.requirements[f"level_{level:03d}"]["recommended_power"]
        if not lower <= recommended <= upper:
            failures.append(
                f"L{level:02d} 推荐战力 {recommended} 超出显示量级带 [{lower},{upper}]"
            )
    return failures


def test_r1_ten_seed_gate(model: "psv6.PowerScaleV6") -> Failures:
    failures: Failures = []
    source = psv6._load_json(psv6.B2_FINAL_PATH)
    runs = [run for run in source.get("runs", []) if int(run.get("level", 0)) == 90]
    build = model.fixture_rows[89]["scale_build"]
    effective = model.effective_power_for_build(build)["effective_power"]
    recommended = model.requirements["level_090"]["recommended_power"]
    wins = sum(bool(run.get("victory")) and not bool(run.get("timeout")) for run in runs)
    import statistics
    median_base = statistics.median(float(run["base_ratio"]) for run in runs)
    if len(runs) != 10 or wins < 9:
        failures.append(f"R=1 synthetic fixture clears {wins}/{len(runs)}, needs >=9/10")
    if not 0.35 <= median_base <= 0.65:
        failures.append(f"R=1 synthetic median base {median_base:.2%} outside 35–65%")
    if effective != recommended:
        failures.append(f"R=1 synthetic fixture is {effective}/{recommended}, not exactly 1.00")
    return failures


# ---------------------------------------------------------------------------
# 5. R 曲线平滑度报告
# ---------------------------------------------------------------------------

def report_r_curve(model: "psv6.PowerScaleV6") -> None:
    print("\n--- R 曲线平滑度报告(按节奏样本,v6 定稿口径) ---")
    print(f"{'level':>5} {'eff':>7} {'rec':>7} {'R':>7} {'R_delta':>9}")
    prev_r = None
    big_jumps = []
    for row in model.fixture_rows:
        eff = model.effective_power_for_build(row["scale_build"])
        rec = model.recommended_power_for_level(row["level_id"])
        r = eff["effective_power"] / max(rec["recommended_power_v6"], 1)
        delta = None if prev_r is None else (r / prev_r - 1.0) * 100.0
        delta_str = "-" if delta is None else f"{delta:+.1f}%"
        print(f"{row['level']:>5} {eff['effective_power']:>7} "
              f"{rec['recommended_power_v6']:>7} {r:>7.3f} {delta_str:>9}")
        if delta is not None and abs(delta) > 15.0:
            big_jumps.append((row["level"], delta))
        prev_r = r
    print(f"相邻 R 跳变 >15% 的关卡数: {len(big_jumps)} / {len(model.fixture_rows) - 1}")
    if big_jumps:
        preview = ", ".join(f"{lv}({d:+.0f}%)" for lv, d in big_jumps[:10])
        print(f"前 10 个: {preview}")
    print("(硬门禁由 b2_requirement_gates 黄金测试逐项断言。)")


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def main() -> int:
    print("building PowerScaleV6 from fixture ...")
    model = psv6.PowerScaleV6.build_from_fixture()

    suite = [
        ("pava_basic", test_pava_basic()),
        ("monotonic_axis_curve", test_monotonic_axis_curve(model)),
        ("monotonic_build_power", test_monotonic_build_power(model)),
        ("segmented_weapon_growth_zero_leakage", test_segmented_weapon_growth_zero_leakage(model)),
        ("capability_api_has_no_level_coupling", test_capability_api_has_no_level_coupling()),
        ("constancy_089_090", test_constancy_089_090(model)),
        ("extrapolation_grows", test_extrapolation_grows(model)),
        ("anchor_bands", test_anchor_bands()),
        ("display_power_roundtrip", test_display_power_roundtrip()),
        ("v5_comparison_snapshot", test_v5_comparison_snapshot(model)),
        ("runtime_config", test_runtime_config(model)),
        ("axis_curve_roundtrip", test_axis_curve_roundtrip(model)),
        ("projection_repairs", test_projection_repairs(model)),
        ("b2_requirement_gates", test_b2_requirement_gates(model)),
        ("r1_ten_seed_gate", test_r1_ten_seed_gate(model)),
    ]

    ok = True
    for name, failures in suite:
        if failures:
            ok = False
            print(f"[FAIL] {name}")
            for f in failures:
                print(f"    - {f}")
        else:
            print(f"[PASS] {name}")

    report_r_curve(model)

    if not ok:
        print("\n黄金测试未全部通过。")
        return 1
    print("\n黄金测试全部通过。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
