#!/usr/bin/env python3
"""Report-only §8.2 bounded-farm closure using the existing account policy.

Rewards are authored full-clear budgets, not a claim that this account actually
earns 3 stars. Dynamic summons, gold-rush cards and premium bonuses are excluded.
"""
from __future__ import annotations

import copy
import datetime as dt
import json
import math
from contextlib import contextmanager
from pathlib import Path

import audit_campaign_frontline as campaign
import simulate_balance as sim
import runtime_power_contracts

ROOT = campaign.ROOT
DATE = dt.datetime.now(dt.timezone(dt.timedelta(hours=8))).strftime("%Y_%m_%d")
MAX_FARM_RUNS = 2000
CHAPTER_FARM_BUDGET = 6
WALL_LEVELS = (15, 17, 18, 19, 20, 40, 44, 76)


def bounded_farm(account, level: dict, previous: dict | None, remaining: int, repeat_offset: int = 0) -> tuple[object, dict]:
    """§8.2: adopt only a copied reference account; never touch saved game data.

    A gate always replays its immediate predecessor. Each predecessor is used
    at only one gate, so count 1 is its second clear (50%), later clears 25%.
    The chapter budget is shared by all gates, not renewed at each gate.
    """
    sandbox = copy.deepcopy(account)
    _, result = campaign.build_for(sandbox, level)
    lower = (result['recommended'] if g1_constrained(level)
             else (95 * result['recommended'] + 99) // 100)
    initial_power = result['power']
    events = []
    while result['power'] < lower and previous is not None and len(events) < remaining:
        count = repeat_offset + len(events) + 1
        full = rewards(previous, first_clear=False)
        multipliers = campaign.TABLES['economy']['repeat_clear_xp_mult']
        multiplier = float(multipliers[min(count, len(multipliers)-1)])
        income = {**full, 'xp': math.floor(full['xp'] * multiplier + .5)}
        event = advance(sandbox, previous, level, income)
        _, result = campaign.build_for(sandbox, level)
        events.append({'repeat_index': count, 'xp_multiplier': multiplier,
                       'power_after': result['power'], **event})
    return sandbox, {'required': initial_power < lower, 'power_before': initial_power,
                     'power_after': result['power'], 'lower': lower,
                     'farm_level': sim.level_number(previous) if previous else None,
                     'runs': len(events), 'budget_available': remaining,
                     'lower_met': result['power'] >= lower, 'events': events,
                     'eight_wall': sim.level_number(level) in WALL_LEVELS}


def g1_constrained(level: dict) -> bool:
    return sim.level_number(level) % 10 in (7, 8, 9) or any(
        sim.runtime_boss_entries(level, wave) for wave in level.get("waves", []))


def g1_envelopes(levels: list[dict]) -> dict[int, int]:
    """design/41 §8.1: E(L)=max(65, rec(1..L)), not a fitted curve."""
    result, running = {}, 65
    for level in levels:
        running = max(running, int(level["clear_requirement"]["power_contract"]["recommended_power"]))
        result[sim.level_number(level)] = running
    return result


def g1_bounds(level: dict, direction_a: bool, envelope: int | None = None) -> tuple[float, float]:
    """Bounds expressed in truthful per-level R; upper bound uses E, not rec."""
    if not direction_a:
        return .95, 1.10
    if envelope is None:
        raise ValueError("direction-A G1 requires the cumulative E envelope")
    rec = int(level["clear_requirement"]["power_contract"]["recommended_power"])
    return (1.00 if g1_constrained(level) else .95), 1.10 * envelope / rec


@contextmanager
def candidate_tables(tables: dict):
    """In-memory resource candidate; preserve the frozen player ruler F(g)."""
    import power_ruler_model as ruler
    from power_scale_v6 import PowerScaleV6
    old_tables = campaign.TABLES
    old_model = getattr(ruler, "_POWER_SCALE_V6_CACHE", None)
    model = copy.copy(old_model or PowerScaleV6.build_from_fixture())
    model.tables = tables  # NEVER refit curves against candidate growth data.
    campaign.TABLES = tables
    ruler._POWER_SCALE_V6_CACHE = model
    try:
        yield
    finally:
        campaign.TABLES = old_tables
        ruler._POWER_SCALE_V6_CACHE = old_model


def runtime_groups(wave: dict) -> list[dict]:
    # battle.gd spawns `support` only in authored boss waves. Do not reuse the
    # legacy audit's unconditional support sum (notably overcounts level 030).
    return list(wave.get("spawns", [])) + (list(wave.get("support", [])) if "boss" in wave else [])


def rewards(level: dict, first_clear: bool = True) -> dict:
    tables = campaign.TABLES
    number = sim.level_number(level)
    economy = tables["economy"]
    per = float(economy["gold_drop_base"]) + float(economy["gold_drop_per_level"]) * number
    multiplier = float(level.get("reward_gold_mult", 1))
    gold = 0
    xp = 0
    extra_xp = 0
    units = 0
    for wave in level["waves"]:
        count_mult = sim.late_wave_count_mult(economy, sim.wave_number(wave), number)
        for group in runtime_groups(wave):
            row = tables["zombies"][group["type"]]
            count = math.floor(int(group["count"]) * count_mult + .5)
            gold += count * math.floor(per * float(row.get("gold_coef", 1)) * multiplier + .5)
            xp += count * int(row.get("run_xp", 1))
            units += count
        for entry in sim.runtime_boss_entries(level, wave):
            row = tables["bosses"][entry["type"]]
            gold += math.floor(per * float(row.get("gold_coef", 1)) * multiplier + .5)
            xp += int(row.get("run_xp", 1))
            if not entry.get("primary", False):
                extra_xp += int(row.get("run_xp", 1))
            units += 1
    budget = int(level.get("run_xp_budget", 0))
    xp = budget + extra_xp if budget else xp
    bonus = int(level.get("first_clear_reward", {}).get("gold", 0)) if first_clear else 0
    return {"gold": gold + bonus, "kill_gold": gold, "first_clear_gold": bonus,
            "xp": xp, "stars": 3 if first_clear else 0, "authored_units": units}


def account_state(account) -> dict:
    return {"gold": account.gold, "xp": account.xp, "stars": account.stars,
            "owned": {slot: sorted(ids) for slot, ids in account.owned.items()},
            "levels": dict(sorted(account.levels.items())), "skills": dict(sorted(account.skills.items())),
            "signature_level": account.signature}


def advance(account, cleared: dict, upcoming: dict, income: dict) -> dict:
    before = account_state(account)
    current, _ = campaign.build_for(account, cleared)
    account.gold += income["gold"]
    account.xp += income["xp"]
    account.stars += income["stars"]
    purchases = campaign.buy_available(account, cleared, campaign.ACTIVE_WEAPON_STRATEGY)
    preferred, _ = campaign.build_for(account, upcoming)
    chapter, element = campaign.purchase_target_after_level(cleared, campaign.ACTIVE_WEAPON_STRATEGY)
    catch_up = campaign.catch_up_target_weapon(account, current["weapon"], chapter, element,
                                               "control", campaign.ACTIVE_WEAPON_STRATEGY)
    spending = campaign.spend_gold(account, campaign.ACTIVE_WEAPON_STRATEGY, income["gold"],
                                    current["weapon"], preferred["weapon"], catch_up)
    campaign.spend_xp(account)
    after = account_state(account)
    upgrades = [{"item": key, "from": before["levels"].get(key, 1), "to": value}
                for key, value in after["levels"].items() if value > before["levels"].get(key, 1)]
    upgrades += [{"skill": key, "from": before["skills"].get(key, 0), "to": value}
                 for key, value in after["skills"].items() if value > before["skills"].get(key, 0)]
    if after["signature_level"] > before["signature_level"]:
        upgrades.append({"skill": "signature", "from": before["signature_level"], "to": after["signature_level"]})
    for weapon in account.owned["weapon"]:
        if campaign.TABLES["weapons"][weapon].get("premium_set") or account.levels[weapon] > 50:
            raise RuntimeError("closure must remain free and weapon levels <=50")
    return {"income": income, "purchases": purchases, "upgrades": upgrades,
            "gold_spent": before["gold"] + income["gold"] - after["gold"],
            "xp_spent": before["xp"] + income["xp"] - after["xp"],
            "resources_after": after, **spending}


def farming_recovery(account, level: dict, previous: dict | None) -> dict:
    build, result = campaign.build_for(account, level)
    recommended = result["recommended"]
    if result["power"] >= recommended:
        return {"repeat_3star_runs": 0, "recovered": True, "R_after": result["power"] / recommended}
    if previous is None:
        return {"repeat_3star_runs": None, "recovered": False, "reason": "no previously cleared level"}
    sandbox = copy.deepcopy(account)
    full = rewards(previous, first_clear=False)
    xp_mults = campaign.TABLES["economy"]["repeat_clear_xp_mult"]
    initial = account_state(account)
    for count in range(1, MAX_FARM_RUNS + 1):
        multiplier = float(xp_mults[min(count, len(xp_mults) - 1)])
        income = {**full, "xp": math.floor(full["xp"] * multiplier + .5)}
        advance(sandbox, previous, level, income)
        build, result = campaign.build_for(sandbox, level)
        if result["power"] >= recommended:
            return {"repeat_3star_runs": count, "recovered": True, "farm_level": sim.level_number(previous),
                    "R_after": result["power"] / recommended, "build_after": build,
                    "additional_gold": count * full["gold"], "additional_stars": 0}
        state = account_state(sandbox)
        # Stop when every owned item and core skill is maxed. More currency
        # cannot increase power; do not claim infinitely many clears will help.
        if all(sandbox.levels[item] >= int(campaign.TABLES[campaign.SLOT_TABLE[slot]][item]["max_level"])
               for slot, ids in sandbox.owned.items() for item in ids) and sandbox.signature == 5 and all(
                   sandbox.skills.get(key, 0) == 5 for key in campaign.CORE_SKILLS if key != "signature"):
            return {"repeat_3star_runs": None, "recovered": False, "farm_level": sim.level_number(previous),
                    "attempted_runs": count, "reason": "owned free build capped below R=1", "R_after": result["power"] / recommended}
    return {"repeat_3star_runs": None, "recovered": False, "attempted_runs": MAX_FARM_RUNS,
            "reason": "finite search limit", "initial": initial, "last": state}


def generate(include_recovery: bool = True) -> dict:
    account = campaign.Account.from_fixture()
    rows = []
    cumulative = {"gold": 0, "xp": 0, "stars": 0}
    first_below = None
    levels = campaign.TABLES["levels"]
    direction_a = runtime_power_contracts.enabled()
    envelopes = g1_envelopes(levels)
    chapter_used = {}
    for index, level in enumerate(levels):
        number = sim.level_number(level)
        chapter = (number - 1) // 10 + 1
        used = chapter_used.get(chapter, 0)
        if direction_a:
            account, farm = bounded_farm(account, level, levels[index-1] if index else None,
                                         CHAPTER_FARM_BUDGET-used)
            chapter_used[chapter] = used + farm['runs']
            farm['chapter_runs_after'] = chapter_used[chapter]
            # Extra runs are diagnostic only, never adopted into the main path.
            if not farm['lower_met'] and include_recovery:
                _, extra = bounded_farm(account, level, levels[index-1] if index else None, 100, farm['runs'])
                farm['additional_runs_counterfactual'] = extra['runs'] if extra['lower_met'] else None
                farm['gate_runs_needed_counterfactual'] = (farm['runs'] + extra['runs']) if extra['lower_met'] else None
                farm['chapter_runs_needed_counterfactual'] = (chapter_used[chapter] + extra['runs']) if extra['lower_met'] else None
                farm['diagnostic_limit'] = 100
            for event in farm['events']:
                for key in cumulative:
                    cumulative[key] += event['income'][key]
        else:
            farm = {'required': False, 'runs': 0, 'chapter_runs_after': 0, 'events': []}
        build, result = campaign.build_for(account, level)
        ratio = result["power"] / result["recommended"]
        if ratio < .95 and first_below is None:
            first_below = sim.level_number(level)
        recovery = (farming_recovery(account, level, levels[index-1] if index else None)
                    if not direction_a and include_recovery else
                    {"not_run": "§8.2 bounded farming is in the reference main path; extra recovery is diagnostic only"})
        envelope = envelopes[sim.level_number(level)]
        minimum, maximum = g1_bounds(level, direction_a, envelope)
        row = {"level": sim.level_number(level), "build": build, "power": result["power"],
               "recommended": result["recommended"], "R": ratio, "cumulative_earned_before": dict(cumulative),
               "account_before": account_state(account), "recovery_counterfactual": recovery, "farming": farm,
               "G1_min_R": minimum, "G1_max_R": maximum,
               "G1_constrained_level": g1_constrained(level) if direction_a else True,
               "E": envelope, "power_over_E": result["power"] / envelope,
               "G1_power_lower": math.ceil(minimum * result["recommended"] - 1e-9),
               "G1_power_upper": (110 * envelope) // 100 if direction_a else math.floor(maximum * result["recommended"] + 1e-9),
               "within_G1_corridor": ratio >= minimum - 1e-12 and ratio <= maximum + 1e-12}
        income = rewards(level)
        row["progression_after_clear"] = advance(account, level, levels[min(index + 1, len(levels) - 1)], income)
        for key in cumulative:
            cumulative[key] += income[key]
        rows.append(row)
    return {"schema_version": 4, "G1_definition": "design/41 section 8.2: all P>=.95rec; Boss/x7-x9 P>=rec; all P<=1.10E; <=6 predecessor farms/chapter; E=max(65,rec(1..L))" if direction_a else "legacy all-level R in [.95,1.10]",
            "assumptions": {"first_clear_stars": 3, "repeat_farming_in_main_path": direction_a,
            "weapon_cap": 50, "strategy": campaign.ACTIVE_WEAPON_STRATEGY,
            "rewards": "full authored kills + first-clear gold; normalized run_xp_budget; no gold-rush/dynamic-summon/premium bonuses",
            "conditional": "all 99 first clears and predecessor farms assumed 3-star; after any failed gate later rows are conditional diagnostics, NOT reachable or runtime wins",
            "repeat_stars": "zero after an already 3-star clear", "repeat_xp": "existing repeat_clear_xp_mult, no first-clear bonus"},
            "first_R_below_0_95": first_below, "rows": rows,
            "total_farm_runs": sum(chapter_used.values()), "chapter_farm_runs": {str(k):v for k,v in chapter_used.items()},
            "farm_gates": [{"level":r['level'], **r['farming']} for r in rows if r['farming']['required']],
            "walls_too_high": [r['level'] for r in rows if direction_a and not r['farming']['lower_met']],
            "envelope_objective": sum(abs(row["power"] - row["E"]) / row["E"] for row in rows),
            "failures": [row["level"] for row in rows if not row["within_G1_corridor"]]}


def render(payload: dict) -> str:
    lines = ["状态：离线条件模拟，不代表实际3★通关；未改数据。", "", "# T3 进度闭环", "",
             "只用假定3★首通，金币按逐敌四舍五入；非Boss波support不计。", 
             "§8.2主路径在账户副本内回刷上一关，每章累计最多6次；未达门槛后的行仅为条件诊断。",
             "不计动态召唤、金币卡、付费助推；按现有购买/升级优先级和技能经验成本。",
             "重复3★没有新增星星，只有金币与递减经验。R是显示战力比，不等于已验证胜率。", "",
             payload["G1_definition"], "",
             f"首次R<0.95：{payload['first_R_below_0_95']}；G1走廊不满足关数：{len(payload['failures'])}/99。", "",
             f"包络目标Σ|P−E|/E：{payload['envelope_objective']:.6f}。", "",
             f"回刷总数：{payload['total_farm_runs']}；各章：{payload['chapter_farm_runs']}；墙过高/预算内未满足下限：{payload['walls_too_high']}。", "",
             "|回刷门|前一关|入门P|回刷后P|次数|章累计|下限满足|八墙关|达到下限所需章次数(反事实)|", "|---|---:|---:|---:|---:|---:|---|---|---|"]
    for gate in payload['farm_gates']:
        needed = gate['chapter_runs_after'] if gate['lower_met'] else gate.get('chapter_runs_needed_counterfactual','未运行')
        lines.append(f"|{gate['level']:03d}|{gate['farm_level']}|{gate['power_before']}|{gate['power_after']}|{gate['runs']}|{gate['chapter_runs_after']}|{gate['lower_met']}|{gate['eight_wall']}|{needed}|")
    lines += ["",
             "|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|当关/章累计回刷|", "|---|---:|---:|---:|---:|---:|---:|---:|---|---|"]
    for row in payload["rows"]:
        progression = row["progression_after_clear"]
        events = [entry["item_id"] for entry in progression["purchases"]]
        events += [f"{entry.get('item', entry.get('skill'))} {entry['from']}→{entry['to']}" for entry in progression["upgrades"]]
        farm = row['farming']
        lines.append(f"|{row['level']:03d}|{row['cumulative_earned_before']['gold']}|{row['power']}|{row['recommended']}|{row['R']:.4f}|{row['E']}|{row['power_over_E']:.4f}|{progression['income']['gold']}|{'; '.join(events) or '无'}|{farm['runs']}/{farm['chapter_runs_after']}|")
    return "\n".join(lines) + "\n"


def write_report(prefix: Path | None = None) -> dict:
    prefix = prefix or ROOT / f"design/audits/progression_closure_{DATE}"
    if not prefix.resolve().is_relative_to(ROOT / "design/audits"):
        raise ValueError("closure output must stay in this worktree's design/audits")
    payload = generate()
    from solve_runtime_clear_lines import atomic_write, input_hashes
    payload["frozen_input_sha256"] = input_hashes()
    prefix.parent.mkdir(parents=True, exist_ok=True)
    atomic_write(prefix.with_suffix(".json"), payload)
    prefix.with_suffix(".md").write_text(render(payload))
    print(f"T3 report={prefix}; first R<0.95={payload['first_R_below_0_95']}; corridor failures={len(payload['failures'])}")
    return payload
