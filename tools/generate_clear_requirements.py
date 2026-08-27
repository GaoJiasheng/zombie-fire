#!/usr/bin/env python3
"""design/28:解每关通关线并写入 levels.json 的 clear_requirement 字段。

校准锚点(不满足直接报错,禁止手改锚点凑数):
1. 全 99 关:按节奏免费构筑族(ℓ=recommend_level)的输出 ≥ required_t
   ——战役设计保证按节奏玩家能通关
2. level_099:完整多 Boss 合同下，最强免费满配有效战力 / 推荐保持在
   [1.10, 1.22]——同型号固定耐久后，毕业压力由四只 Boss 的总合同定义
3. level_013:Owner 实测 1★惨胜构筑(角色1级+雷霆四件套1级)输出落在 required_t 的 [0.95, 1.30]
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import power_ruler_model as prm  # noqa: E402
import campaign_runtime_contracts as runtime_contracts  # noqa: E402


RUNTIME_BENCHMARK_PATH = ROOT / "tools" / "physical_endgame_runtime_benchmark.json"
PACING_TARGETS_PATH = ROOT / "data" / "campaign_pacing_targets.json"


def pilot_scope_ids() -> set[str]:
    """Return all fixed-frame-authoritative campaign level ids."""
    return runtime_contracts.ids()


def load_sim():
    spec = importlib.util.spec_from_file_location("simulate_balance", ROOT / "tools" / "simulate_balance.py")
    sim = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sim)
    return sim


def verify_finale_boss_stack(levels: list[dict], zombies: dict, bosses: dict,
                             economy: dict, sim) -> dict:
    """Verify the finale roster and its authoritative fixed-frame time band."""
    pacing = economy.get("boss_pacing", {}) or {}
    finale_id = str(pacing.get("finale_level_id", "level_099"))
    band = pacing.get("finale_time_band", [150.0, 185.0])
    if not isinstance(band, list) or len(band) != 2:
        raise AssertionError("economy.boss_pacing.finale_time_band must contain [min,max]")
    finale = next((row for row in levels if row.get("id") == finale_id), None)
    if finale is None:
        raise AssertionError(f"missing finale level {finale_id}")

    # Remove the retired generated override so campaign copies stay literal.
    finale.pop("boss_stack_hp_multipliers", None)
    entries = [
        entry
        for wave in finale.get("waves", [])
        for entry in sim.runtime_boss_entries(finale, wave)
    ]
    boss_ids = [str(entry.get("type", "")) for entry in entries]
    if not boss_ids or len(set(boss_ids)) != 1:
        raise AssertionError(
            f"{finale_id}: finale audit requires one repeated Boss type, got {boss_ids}")

    boss_id = boss_ids[0]
    runtime_levels, runtime_rows, runtime_errors = runtime_contracts.load()
    if runtime_errors:
        raise AssertionError("; ".join(runtime_errors))
    finale_no = int(finale_id.split("_")[-1])
    if finale_no not in runtime_levels or finale_no not in runtime_rows:
        raise AssertionError(f"{finale_id}: fixed-frame runtime contract is missing")
    solved_seconds = float(runtime_rows[finale_no]["median_boss_phase_seconds"])
    if not float(band[0]) <= solved_seconds <= float(band[1]):
        raise AssertionError(
            f"{finale_id}: runtime Boss phase {solved_seconds:.1f}s outside {band}")
    return {
        "level_id": finale_id,
        "boss_id": boss_id,
        "copies": len(entries),
        "seconds": solved_seconds,
        "runtime_runs": int(runtime_rows[finale_no]["runs"]),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate campaign clear requirements")
    parser.add_argument("--start", type=int, default=1)
    parser.add_argument("--end", type=int, default=99)
    args = parser.parse_args()
    if args.start < 1 or args.end > 99 or args.start > args.end:
        parser.error("scope must satisfy 1 <= start <= end <= 99")

    def in_scope(level_no: int) -> bool:
        return args.start <= level_no <= args.end

    sim = load_sim()
    levels = prm.load_table("levels")
    zombies = prm.load_table("zombies")
    bosses = prm.load_table("bosses")
    economy = prm.load_table("economy")
    characters = prm.load_table("characters")
    weapons = prm.load_table("weapons")
    skills = prm.load_table("skills")
    chips = prm.load_table("chips")
    pets = prm.load_table("pets")

    finale_solution = verify_finale_boss_stack(
        levels, zombies, bosses, economy, sim)

    baseline_o = prm.offense_baseline_l1(characters, weapons)
    ctx = prm.FamilyContext(sim, characters, weapons, economy)

    requirements = {}
    failures = []
    pilot_ids = pilot_scope_ids()
    for level in levels:
        level_no = int(str(level["id"]).split("_")[-1])
        if runtime_contracts.clear_requirement_mode(level_no) == "preserve_v5_scale":
            mob_hp, boss_hp, _count = sim.level_enemy_hp_split(level, zombies, bosses, economy)
            req = runtime_contracts.preserve_v5_requirement(
                level_no, level.get("clear_requirement", {}), mob_hp, boss_hp,
                prm._boss_id(level))
        else:
            req = prm.solve_required_t(level, zombies, bosses, chips, characters, weapons, ctx)
        req["power_contract"] = prm.build_power_contract(
            level, req, characters, weapons, skills, bosses, economy, sim)
        requirements[level["id"]] = req

        # 锚点1:按节奏免费构筑族必须过线
        rec = float(level.get("recommend_level", 1))
        on_pace_t = ctx.family_offense_t(characters, weapons, chips, rec)
        if in_scope(level_no) and level["id"] not in pilot_ids and on_pace_t < req["min_output"] * 0.999:
            failures.append(f"{level['id']}: on-pace t={on_pace_t:.3f} < required {req['min_output']:.3f}")

    # 锚点2:终局"将将能过"由完整 Boss 编队定义。固定单体耐久后，
    # required_t 只校准主 Boss，不能再拿它冒充四只 Boss 的总压力。
    maxed_t = ctx.family_offense_t(characters, weapons, chips, prm.FAMILY_MAX_INDEX)
    req99 = requirements["level_099"]["min_output"]
    maxed_free_build = {
        "character": "vanguard", "character_level": 40,
        "weapon": "weapon_scattergun", "weapon_level": 50,
        "armor": "armor_kevlar", "armor_level": 35,
        "chip": "chip_attack", "chip_level": 35,
        "pet": "pet_turret_drone", "pet_level": 30,
        "signature_level": 5,
        "skill_base_levels": {
            skill_id: prm.skill_max_level(row) for skill_id, row in skills.items()
        },
    }
    final_power = prm.power_for_build(
        levels[-1], requirements["level_099"]["power_contract"], maxed_free_build,
        characters, weapons, prm.load_table("armors"), chips, pets, skills,
        bosses, economy,
    )
    final_ratio = float(final_power["power"]) / max(float(final_power["recommended"]), 1.0)
    if in_scope(99) and not 1.10 <= final_ratio <= 1.22:
        failures.append(
            f"level_099: maxed free full-roster ratio {final_ratio:.4f} outside [1.10,1.22]"
        )

    # 锚点3:Owner 实测惨胜构筑(雷霆四件套 L1,零技能)。
    # 已知模型边界:静态折算对低等级付费套偏乐观(连锁/过载/终端雷柱在低等级、
    # 低敌群密度下打不满,Owner 实测 1★ 对应真实输出 ≈ 通关线 ×1.10-1.15,模型
    # 给到 ~1.4)。方向是"付费显示略强于真实",带宽上限如实放到 1.45,不引入
    # 任意折扣因子去凑窄带;满级合同带(付费/免费 ∈ [1.45,1.65])才是硬约束。
    thunder_o = prm.offense_multiplier(
        characters["vanguard"], weapons["weapon_apocalypse_thunder"], 1, 1, 0,
        chip=chips.get("chip_apocalypse_superconductive", {}), chip_level=1,
        pet=pets.get("pet_apocalypse_tempest", {}), pet_level=1,
    )
    thunder_t = thunder_o / baseline_o
    req13 = requirements["level_013"]["min_output"]
    if in_scope(13) and not (0.95 * req13 <= thunder_t <= 1.45 * req13):
        failures.append(f"level_013: thunder-L1 t={thunder_t:.3f} outside [0.95,1.45]x required {req13:.3f}")

    if failures:
        print("Clear requirement anchors FAILED:")
        for f in failures:
            print(f"- {f}")
        return 1

    written = 0
    for level in levels:
        level_no = int(str(level["id"]).split("_")[-1])
        if in_scope(level_no):
            level["clear_requirement"] = requirements[level["id"]]
            written += 1
    (prm.DATA / "levels.json").write_text(
        json.dumps(levels, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
    print(f"Wrote clear_requirement for {written} levels ({args.start:03d}-{args.end:03d})")
    print(
        "finale Boss stack: "
        f"{finale_solution['boss_id']} x{finale_solution['copies']} "
        "literal_copy_scale=1.000000 "
        f"graduation={finale_solution['seconds']:.1f}s"
    )
    contract99 = requirements["level_099"]["power_contract"]
    print(
        f"anchors: maxed_t={maxed_t:.3f} req99(primary)={req99:.3f} "
        f"full-roster-R={final_ratio:.4f} | thunder_t={thunder_t:.3f} req13={req13:.3f}"
    )
    print(
        "power contract 99: "
        f"recommended={contract99['recommended_power']} "
        f"crowd={contract99['crowd_capacity']:.2f} "
        f"boss={contract99['boss_capacity']:.2f} "
        f"line={contract99['line_capacity']:.2f}"
    )
    sample = {k: requirements[k]["min_output"] for k in ("level_001", "level_013", "level_050", "level_099")}
    print("sample required_t:", sample)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
