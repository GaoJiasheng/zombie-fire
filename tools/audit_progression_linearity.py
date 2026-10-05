#!/usr/bin/env python3
"""T2: read-only progression/real-clear-line audit. --check reports violations.

No smoothing or tuning is performed. Missing/censored P* and extrapolated
win-rate predictions cannot pass a complete-data contract.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import math
from pathlib import Path
import statistics

import audit_campaign_frontline as campaign
import power_ruler_model as ruler
import simulate_balance as sim
from solve_runtime_clear_lines import atomic_write, input_hashes

ROOT = campaign.ROOT
DATE = dt.datetime.now(dt.timezone(dt.timedelta(hours=8))).strftime("%Y_%m_%d")
CHAPTER_SLOPE_DEVIATION_PP = 3.0
ADJACENT_GROWTH_DIFFERENCE_PP = 3.0
RESOURCE_CORRELATION_MIN = .98
RESOURCE_GROWTH_DIFFERENCE_PP = 2.0
BOSS_EXTRA_STEP_PP = 10.0
CLIFF_NORMAL_GROWTH = .15
CLIFF_BOSS_EDGE_GROWTH = .25
PREDICTION_CONTRACT = {.85: (3, 7), 1.0: (9, 10), 1.15: (10, 10)}


def growth(current: float | None, previous: float | None) -> float | None:
    return current / previous - 1 if current is not None and previous is not None and previous > 0 else None


def pearson(pairs: list[tuple[float, float]]) -> float | None:
    if len(pairs) < 3:
        return None
    xbar = statistics.mean(x for x, _ in pairs)
    ybar = statistics.mean(y for _, y in pairs)
    xx = sum((x - xbar) ** 2 for x, _ in pairs)
    yy = sum((y - ybar) ** 2 for _, y in pairs)
    if xx <= 0 or yy <= 0:
        return None
    return sum((x - xbar) * (y - ybar) for x, y in pairs) / math.sqrt(xx * yy)


def geometric_slope(pairs: list[tuple[int, float]]) -> float | None:
    pairs = [(x, math.log(y)) for x, y in pairs if y is not None and y > 0]
    if len(pairs) < 2:
        return None
    xbar = statistics.mean(x for x, _ in pairs)
    ybar = statistics.mean(y for _, y in pairs)
    denominator = sum((x - xbar) ** 2 for x, _ in pairs)
    if denominator == 0:
        return None
    slope = sum((x - xbar) * (y - ybar) for x, y in pairs) / denominator
    return math.expm1(slope)


def isotonic_fit(samples: list[tuple[float, int]]) -> list[dict]:
    """Weighted PAVA on ten-seed empirical rates, pooling identical R values."""
    by_x: dict[float, list[int]] = {}
    for x, wins in samples:
        by_x.setdefault(x, []).append(wins)
    blocks = []
    for x in sorted(by_x):
        values = by_x[x]
        blocks.append({"xs": [x], "wins": sum(values), "trials": len(values) * 10})
        while len(blocks) >= 2 and blocks[-2]["wins"] / blocks[-2]["trials"] > blocks[-1]["wins"] / blocks[-1]["trials"]:
            right = blocks.pop()
            left = blocks.pop()
            blocks.append({"xs": left["xs"] + right["xs"], "wins": left["wins"] + right["wins"], "trials": left["trials"] + right["trials"]})
    return [{"R": x, "rate": block["wins"] / block["trials"]} for block in blocks for x in block["xs"]]


def predict(knots: list[dict], x: float) -> dict:
    if not knots:
        return {"R": x, "expected_wins": None, "supported": False}
    supported = knots[0]["R"] <= x <= knots[-1]["R"]
    rate = knots[0]["rate"] if x <= knots[0]["R"] else knots[-1]["rate"]
    for left, right in zip(knots, knots[1:]):
        if left["R"] <= x <= right["R"]:
            t = (x - left["R"]) / (right["R"] - left["R"])
            rate = left["rate"] * (1 - t) + right["rate"] * t
            break
    lower, upper = PREDICTION_CONTRACT[x]
    wins = rate * 10
    return {"R": x, "expected_wins": wins, "supported": supported,
            "contract_wins": [lower, upper], "deviation_wins": max(lower - wins, wins - upper, 0),
            "interpretation": "interpolated model estimate, not a new ten-seed runtime test" if supported else "endpoint extrapolation; contract not verified"}


def resource_comparison(name: str, values: dict[int, float], rows: list[dict]) -> dict:
    result = {"curve": name, "values": values, "comparisons": {}}
    for metric in ("recommended", "p_star"):
        pairs = [(values[row["level"]], row[metric]) for row in rows if row.get(metric) is not None and row["level"] in values]
        differences = []
        for previous, current in zip(rows, rows[1:]):
            a, b = previous["level"], current["level"]
            resource_delta = growth(values.get(b), values.get(a))
            target_delta = growth(current.get(metric), previous.get(metric))
            if resource_delta is not None and target_delta is not None:
                differences.append({"level": b, "resource_growth": resource_delta,
                                    "target_growth": target_delta, "difference_pp": (resource_delta - target_delta) * 100})
        result["comparisons"][metric] = {"correlation": pearson(pairs), "sample_count": len(pairs),
                                           "growth_differences": differences,
                                           "over_2pp_levels": [item["level"] for item in differences if abs(item["difference_pp"]) > RESOURCE_GROWTH_DIFFERENCE_PP]}
    return result


def catalog() -> dict:
    tables = campaign.TABLES
    thresholds = []
    def walk(value, pointer: str, file: str):
        if isinstance(value, dict):
            for key, item in value.items():
                here = pointer + "/" + key
                if "star" in key.lower():
                    thresholds.append({"file": file, "pointer": here, "value": item})
                walk(item, here, file)
        elif isinstance(value, list):
            for index, item in enumerate(value):
                walk(item, pointer + "/" + str(index), file)
    for path in sorted((ROOT / "data").glob("*.json")):
        walk(json.loads(path.read_text()), "", str(path.relative_to(ROOT)))
    weapons = {}
    for key, weapon in tables["weapons"].items():
        weapons[key] = {"max_level": weapon["max_level"], "premium": bool(weapon.get("premium_set")),
                        "level_growth_segments": weapon.get("level_growth_segments", []),
                        "level_rows": [{"level": lv, "next_upgrade_gold": campaign.upgrade_cost(weapon, lv) if lv < weapon["max_level"] else None,
                                        "damage_multiplier": ruler.weapon_level_damage_multiplier(weapon, lv),
                                        "DPS_multiplier": ruler.weapon_dps_multiplier(weapon, lv, "tier_b")}
                                       for lv in range(1, int(weapon["max_level"]) + 1)]}
    return {"star_fields": thresholds, "weapons": weapons,
            "skill_base_xp_costs": tables["economy"]["skill_base_xp_costs"],
            "sig_skill_xp_costs": tables["economy"]["sig_skill_xp_costs"]}


def threat_inventory() -> list[dict]:
    """Nominal contact threat: 20 seconds uninterrupted, before mitigation.

    This is explicitly not a full combat loss forecast (shield/control/deaths
    and random timing matter). Include a reference base HP denominator per
    authored appearance, keeping 100%-HP boss clears explainable, not ignored.
    """
    fixtures = {row["level"]: row["build"] for row in json.loads(campaign.BUILD_REPORT.read_text())["rows"]}
    result = []
    for table_name in ("bosses", "zombies"):
        for key, enemy in campaign.TABLES[table_name].items():
            boss = table_name == "bosses"
            mechanic = enemy.get("mechanic", "")
            mult, interval = 1.0, 1.35
            if mechanic in {"runner", "low_profile", "leap", "charge", "phase", "phase_shift"}:
                mult, interval = .72, .82
            elif mechanic in {"tank", "armor", "armor_break", "juggernaut", "shield_aura", "ward", "multi_phase"}:
                mult, interval = 1.38, 1.72
            elif mechanic in {"explode_on_death", "phase_burn"}:
                mult, interval = 1.18, 1.46
            elif mechanic in {"ranged_spit", "toxic_cloud", "regenerate", "spawn_minions"}:
                mult, interval = .86, 1.12
            elif mechanic in {"buff_aura", "summon"}:
                mult, interval = .76, 1.05
            # setup() truncates breach_damage before _configure_base_attack
            # rounds its mechanic multiplier; keep those two operations distinct.
            damage = max(1, math.floor(int(10 * float(enemy.get("bd_coef", 1))) * mult + .5))
            if boss:
                damage = math.floor(max(1, damage) * 1.35 + .5)
                interval += .28
            params = enemy.get("mechanic_params", {})
            damage = int(params.get("base_attack_damage", max(1, damage)))
            interval = float(params.get("base_attack_interval", interval))
            profile = params.get("base_attack_profile", {}) if boss else {}
            delay = float(profile.get("first_attack_delay", -1))
            delay = delay if delay >= 0 else .21  # mean of runtime U(.08,.34)
            if profile:
                contact = max(0, float(profile.get("windup", .48)))
                contact += (max(1, int(profile.get("hits", 1))) - 1) * max(.02, float(profile.get("hit_gap", .12)))
                contact += max(0, float(profile.get("travel_time", 0)))
                duration = contact
            else:
                animation = enemy.get("attack_animation", {})
                duration = max(.24, float(animation.get("duration", .48)))
                contact = duration * min(.8, max(.25, float(animation.get("contact_ratio", .5))))
            # Timer runs during the animation, so each round takes the larger
            # of nominal interval and sequence duration. Ignore 1/60 frame slop.
            effective_interval = max(interval, duration)
            attacks = max(0, 1 + math.floor((20 - delay - contact) / effective_interval))
            appearances = []
            for level in campaign.TABLES["levels"]:
                number = sim.level_number(level)
                present = any(any(entry["type"] == key for entry in sim.runtime_boss_entries(level, wave)) if boss else
                              any(group["type"] == key for group in __import__("progression_closure").runtime_groups(wave)) for wave in level["waves"])
                if present:
                    build = fixtures[number]
                    power = campaign.power_for_build(level, level["clear_requirement"]["power_contract"], build,
                                                      *(campaign.TABLES[name] for name in ("characters", "weapons", "armors", "chips", "pets", "skills", "bosses", "economy")))
                    base = campaign.base_hp(level, build, power["projected_skills"])
                    appearances.append({"level": number, "reference_base_hp": base,
                                        "nominal_contact_loss_20s_pct": damage * attacks / base * 100})
            result.append({"enemy": key, "kind": "boss" if boss else "ordinary/elite", "mechanic": mechanic,
                           "damage_per_round": damage, "nominal_interval": interval,
                           "effective_nominal_interval": effective_interval, "first_contact_delay": delay + contact,
                           "contact_damage_20s": damage * attacks,
                           "appearances": appearances,
                           "limitations": "pre-mitigation contact budget; no random interval, shield, control, regen, death, remote or spawned-enemy damage; denominator is shared analytical base-HP estimate"})
    return result


def boss_clear_evidence(source: dict) -> list[dict]:
    """Explain only what existing probe reports establish; never invent contact."""
    observations = []
    for row in source.get("rows", []):
        if not any("boss" in wave for wave in campaign.TABLES["levels"][row["level"] - 1]["waves"]):
            continue
        step = next((item for item in row.get("steps", []) if item["scale"] == 1), None)
        if not step:
            continue
        path = Path(step["evidence"])
        if not path.is_file():
            observations.append({"level": row["level"], "evidence_missing": str(path)})
            continue
        for run in json.loads(path.read_text())["runs"]:
            report = run.get("battle_report", {})
            taken = report.get("base_damage_taken")
            prevented = report.get("base_damage_prevented")
            full_hp = run["victory"] and run["base_ratio"] >= .999999
            if not full_hp:
                explanation = "not a full-HP clear"
            elif prevented:
                explanation = "full final HP with mitigation recorded; not evidence of harmless enemies"
            elif taken:
                explanation = "full final HP despite recorded damage; healing/rounding requires timeline review"
            else:
                explanation = "no base damage recorded; existing aggregate probe cannot distinguish kill-before-contact from delayed/control-suppressed attacks"
            observations.append({"level": row["level"], "seed": run["seed"], "victory": run["victory"],
                                 "base_ratio": run["base_ratio"], "full_hp_clear": full_hp,
                                 "base_damage_taken": taken, "base_damage_prevented": prevented,
                                 "max_progress": run.get("max_progress"), "boss_phase_seconds": run.get("boss_phase_seconds"),
                                 "boss_hp_ratio_at_end": run.get("boss_hp_ratio_at_end"), "explanation": explanation,
                                 "evidence": str(path)})
    return observations


def audit(source: dict, closure: dict | None) -> dict:
    solved = {int(row["level"]): row for row in source.get("rows", [])}
    star_rows = {int(row["level"]): row for row in csv.DictReader(campaign.REPORT.with_name("b2b_star_table_old_to_new.csv").open())}
    rows = []
    for level in campaign.TABLES["levels"]:
        number = sim.level_number(level)
        clear = solved.get(number, {})
        mob, boss, count = sim.level_enemy_hp_split(level, campaign.TABLES["zombies"], campaign.TABLES["bosses"], campaign.TABLES["economy"])
        rows.append({"level": number, "chapter": (number - 1) // 10 + 1,
                     "recommended": int(level["clear_requirement"]["power_contract"]["recommended_power"]),
                     "p_star": clear.get("p_star") if clear.get("status") == "complete" else None,
                     "r_star": clear.get("r_star") if clear.get("status") == "complete" else None,
                     "solve_status": clear.get("status", "not_run"), "difficulty_coef": float(level["difficulty_coef"]),
                     "enemy_hp": mob + boss, "mob_hp": mob, "boss_hp": boss, "enemy_count": count,
                     "boss": any("boss" in wave for wave in level["waves"]), "archived_star_row": star_rows.get(number)})
    metrics = ("recommended", "p_star", "difficulty_coef", "enemy_hp")
    for index, row in enumerate(rows):
        row["growth"] = {metric: growth(row[metric], rows[index - 1][metric]) if index else None for metric in metrics}
    chapters = []
    violations = []
    missing = [row["level"] for row in rows if row["p_star"] is None]
    if missing:
        violations.append({"contract": "complete_T1", "levels": missing})
    for chapter in range(1, 11):
        chunk = [row for row in rows if row["chapter"] == chapter]
        slopes = {metric: geometric_slope([(row["level"], row[metric]) for row in chunk]) for metric in metrics}
        departures = []
        for row in chunk:
            for metric in metrics:
                delta = row["growth"][metric]
                if delta is None or slopes[metric] is None or row["level"] == chunk[0]["level"]:
                    continue
                deviation = (delta - slopes[metric]) * 100
                if abs(deviation) > CHAPTER_SLOPE_DEVIATION_PP:
                    departures.append({"level": row["level"], "metric": metric, "deviation_pp": deviation, "boss": row["boss"]})
                if metric == "p_star" and (deviation < -CHAPTER_SLOPE_DEVIATION_PP or
                                           deviation > (BOSS_EXTRA_STEP_PP if row["boss"] else CHAPTER_SLOPE_DEVIATION_PP)):
                    violations.append({"contract": "chapter_P_star_slope", "level": row["level"], "deviation_pp": deviation})
        samples = [(step["R"], step["wins"]) for row in source.get("rows", []) if (row["level"] - 1) // 10 + 1 == chapter
                   for step in row.get("steps", []) if not step.get("reused_from_scale")]
        knots = isotonic_fit(samples)
        predictions = [predict(knots, ratio) for ratio in PREDICTION_CONTRACT]
        for prediction in predictions:
            if not prediction["supported"] or prediction.get("deviation_wins", 0) > 1e-9:
                violations.append({"contract": "G3_predicted_rate", "chapter": chapter, **prediction})
        chapters.append({"chapter": chapter, "sample_count": len(samples), "slopes": slopes,
                         "departures_over_3pp": departures, "boss_steps": [{"level": row["level"], "growth": row["growth"]} for row in chunk if row["boss"]],
                         "win_rate_fit": knots, "predictions": predictions})
    cliffs = []
    for previous, current in zip(rows, rows[1:]):
        delta = current["growth"]["p_star"]
        edge = previous["boss"] or current["boss"]
        if delta is not None:
            if delta < 0:
                violations.append({"contract": "P_star_monotonic", "level": current["level"], "growth": delta})
            if delta > (CLIFF_BOSS_EDGE_GROWTH if edge else CLIFF_NORMAL_GROWTH):
                cliffs.append({"level": current["level"], "kind": "P_star_growth", "growth": delta, "boss_edge": edge})
            last_growth = previous["growth"]["p_star"]
            if last_growth is not None and abs(delta - last_growth) * 100 > ADJACENT_GROWTH_DIFFERENCE_PP:
                violations.append({"contract": "adjacent_growth_delta", "level": current["level"], "difference_pp": (delta - last_growth) * 100})
        # Same-account adjacent full-clear baseline only; weaker builds are NOT
        # comparable between stages. Different fixture builds remain explicit.
        a = next((step for step in solved.get(previous["level"], {}).get("steps", []) if step["scale"] == 1), None)
        b = next((step for step in solved.get(current["level"], {}).get("steps", []) if step["scale"] == 1), None)
        if a and b and a["wins"] == 10 and b["wins"] <= 3:
            cliffs.append({"level": current["level"], "kind": "baseline_10_to_le3", "previous_base_median": a["base_median"], "different_reference_builds": a["build"] != b["build"]})
    violations.extend({"contract": "cliff", **cliff} for cliff in cliffs)
    economy = campaign.TABLES["economy"]
    curves = {"first_clear_gold_formula": {}, "first_clear_reward.gold": {}, "reward_gold_mult": {}}
    for level in campaign.TABLES["levels"]:
        number = sim.level_number(level)
        curves["first_clear_gold_formula"][number] = economy["first_clear_gold_base"] + economy["first_clear_gold_per_level"] * number
        curves["first_clear_reward.gold"][number] = int(level["first_clear_reward"]["gold"])
        curves["reward_gold_mult"][number] = float(level["reward_gold_mult"])
    if closure:
        extra_names = ("earned_gold_cumulative", "earned_xp_cumulative", "earned_stars_cumulative", "star_unlock_spending_cumulative", "equipped_weapon_upgrade_cost", "equipped_weapon_growth", "permanent_skill_next_xp_cost")
        curves.update({name: {} for name in extra_names})
        spent_stars = 0
        for row in closure["rows"]:
            number, build = row["level"], row["build"]
            for currency in ("gold", "xp", "stars"):
                curves[f"earned_{currency}_cumulative"][number] = row["cumulative_earned_before"][currency]
            curves["star_unlock_spending_cumulative"][number] = spent_stars
            spent_stars += sum(event["star_cost"] for event in row["progression_after_clear"]["purchases"])
            weapon = campaign.TABLES["weapons"][build["weapon"]]
            curves["equipped_weapon_upgrade_cost"][number] = campaign.upgrade_cost(weapon, build["weapon_level"])
            curves["equipped_weapon_growth"][number] = ruler.weapon_dps_multiplier(weapon, build["weapon_level"], "tier_b")
            costs = economy["skill_base_xp_costs"]
            curves["permanent_skill_next_xp_cost"][number] = sum(costs[lv] if lv < len(costs) else 0 for lv in build["skill_base_levels"].values())
        violations.extend({"contract": "G1_closure_corridor", "level": number} for number in closure["failures"])
    else:
        violations.append({"contract": "G1_closure_missing"})
    resources = [resource_comparison(name, values, rows) for name, values in curves.items()]
    for resource in resources:
        for metric, comparison in resource["comparisons"].items():
            if comparison["correlation"] is None or comparison["correlation"] < RESOURCE_CORRELATION_MIN or comparison["over_2pp_levels"]:
                violations.append({"contract": "G1_resource_curve", "curve": resource["curve"], "target": metric,
                                   "correlation": comparison["correlation"], "over_2pp_levels": comparison["over_2pp_levels"]})
    def bias(numbers, expected):
        numbers = list(numbers)
        values = [solved[n]["r_star"] for n in numbers if solved.get(n, {}).get("status") == "complete"]
        shortfalls = [(1 - value) * 100 for value in values]
        matched = (all(value > 1 for value in values) if expected == "low" else
                   all(value < 1 for value in values) if expected == "high" else
                   all(12 <= value <= 40 for value in shortfalls))
        return {"observed_levels": [n for n in numbers if solved.get(n, {}).get("status") == "complete"],
                "status": "unmeasured" if not values else ("reproduced" if matched else "differs") if len(values) == len(numbers) else "partial",
                "median_r_star": statistics.median(values) if values else None,
                "shortfall_as_pct_of_recommendation": shortfalls,
                "recommended_excess_as_pct_of_P_star": [(1 / value - 1) * 100 for value in values],
                "observed_match": matched if values else None}
    return {"schema_version": 1, "combat_input_fingerprint": source.get("combat_input_fingerprint"),
            "complete_measurement": not missing and not source.get("errors"), "rows": rows, "chapters": chapters,
            "resource_curves": resources, "resource_catalog": catalog(), "cliffs": cliffs,
            "known_fact_reproduction": {"ch2_recommendations_low": bias(range(11, 21), "low"), "035_recommendation_high": bias([35], "high"), "060_099_recommendations_high_12_40_pct": bias(range(60, 100), "12_40")},
            "threat_inventory": threat_inventory(), "boss_reference_evidence": boss_clear_evidence(source), "violations": violations,
            "limits": ["T1 is a scaled reference ray, not a search of all builds.",
                       "R fits pool reference families within each chapter; predictions are not new gameplay runs.",
                       "Archived star CSV is historical context, not current runtime proof.",
                       "Resource stage-indexed correlations use T3 actual hypothetical account progress, not a fabricated rank mapping.",
                       "100%-HP boss results do not prove zero threat: consult contact inventory and raw wave/boss timelines; reach-line and kill-time explanations require full runtime evidence."]}


def fmt(value, percent=False):
    return "未测/不可估" if value is None else (f"{value * 100:.2f}%" if percent else f"{value:.4f}")


def render(payload: dict) -> str:
    lines = [f"状态：{'全量已测' if payload['complete_measurement'] else '测量不完整'}；门禁{'失败' if payload['violations'] else '通过'}；未改数据。", "", "# T2 线性度与战力真实化审计", "",
             "章节log(value)~关卡号OLS拟合几何斜率；逐关增幅与章斜率相差>3pp单列，Boss允许额外+10pp。",
             "R→胜率使用十种子数据的加权保序回归(PAVA)+线性插值，不在已测区间内即未验证。", "",
             "## 逐关增幅", "", "|关|推荐|P*|R*|系数|总血量|推荐增幅|P*增幅|系数增幅|血量增幅|求解状态|", "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|"]
    for row in payload["rows"]:
        lines.append(f"|{row['level']:03d}|{row['recommended']}|{row['p_star'] or '未测'}|{fmt(row['r_star'])}|{row['difficulty_coef']:.3f}|{row['enemy_hp']:.0f}|" + "|".join(fmt(row["growth"][key], True) for key in ("recommended", "p_star", "difficulty_coef", "enemy_hp")) + f"|{row['solve_status']}|")
    lines += ["", "## 章节斜率与胜率合同", "", "|章|推荐斜率|P*斜率|系数斜率|血量斜率|R=.85预计胜数|R=1预计胜数|R=1.15预计胜数|", "|---|---:|---:|---:|---:|---|---|---|"]
    for chapter in payload["chapters"]:
        preds = [fmt(item.get("expected_wins")) + ("/10" if item["supported"] else "(外推/未验)") for item in chapter["predictions"]]
        lines.append(f"|{chapter['chapter']}|" + "|".join(fmt(chapter["slopes"][key], True) for key in ("recommended", "p_star", "difficulty_coef", "enemy_hp")) + "|" + "|".join(preds) + "|")
        lines.append(f"\n章{chapter['chapter']}偏離>3pp：`{json.dumps(chapter['departures_over_3pp'], ensure_ascii=False)}`；Boss台阶：`{json.dumps(chapter['boss_steps'], ensure_ascii=False)}`\n")
    lines += ["", "## 资源曲线", "", "|曲线|对推荐相关|对P*相关|对P*逐关增幅差>2pp|", "|---|---:|---:|---|"]
    for row in payload["resource_curves"]:
        lines.append(f"|{row['curve']}|{fmt(row['comparisons']['recommended']['correlation'])}|{fmt(row['comparisons']['p_star']['correlation'])}|{row['comparisons']['p_star']['over_2pp_levels']}|")
    lines += ["", "### 星星门槛来源", ""]
    for row in payload["resource_catalog"]["star_fields"]:
        lines.append(f"- `{row['file']}{row['pointer']}` = `{json.dumps(row['value'],ensure_ascii=False)}`")
    lines += ["", "### 成长与成本目录", "", "所有免费/付费武器逐级成本、伤害成长与DPS成长保存在JSON的resource_catalog.weapons；按数据段计算，不用假定线性。",
              f"技能XP成本：{payload['resource_catalog']['skill_base_xp_costs']}；专属技能：{payload['resource_catalog']['sig_skill_xp_costs']}。", "",
              "## 已知事实复现", "", f"```json\n{json.dumps(payload['known_fact_reproduction'],ensure_ascii=False,indent=2)}\n```", "",
              "ch2 R*>1才证明推荐偏低，035 R*<1才证明偏高。060–099的12–40%按(推荐−P*)/推荐=1−R*统计，另列以P*为分母的超额百分比，避免混用；未测不写复现。", "",
              "## 悬崖", "", f"`{json.dumps(payload['cliffs'],ensure_ascii=False)}`", "",
              "## 逐敌威胁 (§40.13)", "", "下表是单体到线20秒的减伤前预算，不等于实际损血。按参考构筑的基地HP估计比例详见JSON的appearances，护盾/控场/远程/召唤等尚未建模。", "",
              "|敌人|机制|每轮伤害|间隔|20秒接触伤害|", "|---|---|---:|---:|---:|"]
    for row in payload["threat_inventory"]:
        lines.append(f"|{row['enemy']}|{row['mechanic']}|{row['damage_per_round']}|{row['nominal_interval']}|{row['contact_damage_20s']}|")
    lines += ["", "### Boss满血通关解释", "", "每种子列出接触进度、Boss持续时间、基地受伤/减免，详见JSON的boss_reference_evidence。",
              "未记录损血不能直接解释成Boss没有攻击：现有汇总探针不能区分未到线即被击杀和控场/前摇阻止结算；明确保留此证据缺口，不将100%基地余量当作Boss无威胁的证明。"]
    lines += ["", "## 门禁失败与限制", "", f"失败项：{len(payload['violations'])}；明细见同名JSON。"] + [f"- {item}" for item in payload["limits"]]
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime-lines", type=Path, default=ROOT / f"design/audits/runtime_clear_lines_{DATE}.json")
    parser.add_argument("--closure", type=Path, default=ROOT / f"design/audits/progression_closure_{DATE}.json")
    parser.add_argument("--output", type=Path, default=ROOT / f"design/audits/progression_linearity_{DATE}", help="audit report prefix")
    parser.add_argument("--check", action="store_true", help="return 1 for contract violations/incomplete evidence; never rewrite data")
    options = parser.parse_args()
    if not options.output.resolve().is_relative_to(ROOT / "design/audits"):
        parser.error("output must be in this worktree's design/audits")
    source = json.loads(options.runtime_lines.read_text())
    import run_frontline_sweep as sweep
    if source.get("combat_input_fingerprint") != sweep.combat_input_fingerprint(ROOT):
        parser.error("runtime combat fingerprint differs from current frozen inputs")
    if source.get("frozen_input_sha256") != input_hashes():
        parser.error("runtime full frozen-input hashes differ from current inputs")
    closure = json.loads(options.closure.read_text()) if options.closure.is_file() else None
    if closure and closure.get("frozen_input_sha256") != input_hashes():
        parser.error("closure frozen-input hashes differ from current inputs")
    payload = audit(source, closure)
    payload["runtime_source"] = str(options.runtime_lines)
    payload["closure_source"] = str(options.closure) if closure else None
    payload["thresholds"] = {key: value for key, value in globals().items() if key.isupper() and isinstance(value, (int, float))}
    atomic_write(options.output.with_suffix(".json"), payload)
    options.output.with_suffix(".md").write_text(render(payload))
    print(f"T2 measured={sum(row['p_star'] is not None for row in payload['rows'])}/99; violations={len(payload['violations'])}; report={options.output}")
    return 1 if options.check and payload["violations"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
