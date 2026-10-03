#!/usr/bin/env python3
"""Report-only three-star/no-farm closure using the existing account policy.

Rewards are authored full-clear budgets, not a claim that this account actually
earns 3 stars. Dynamic summons, gold-rush cards and premium bonuses are excluded.
"""
from __future__ import annotations

import copy
import datetime as dt
import json
import math
from pathlib import Path

import audit_campaign_frontline as campaign
import simulate_balance as sim

ROOT = campaign.ROOT
DATE = dt.datetime.now(dt.timezone(dt.timedelta(hours=8))).strftime("%Y_%m_%d")
MAX_FARM_RUNS = 2000


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


def generate() -> dict:
    account = campaign.Account.from_fixture()
    rows = []
    cumulative = {"gold": 0, "xp": 0, "stars": 0}
    first_below = None
    levels = campaign.TABLES["levels"]
    for index, level in enumerate(levels):
        build, result = campaign.build_for(account, level)
        ratio = result["power"] / result["recommended"]
        if ratio < .95 and first_below is None:
            first_below = sim.level_number(level)
        recovery = farming_recovery(account, level, levels[index - 1] if index else None)
        row = {"level": sim.level_number(level), "build": build, "power": result["power"],
               "recommended": result["recommended"], "R": ratio, "cumulative_earned_before": dict(cumulative),
               "account_before": account_state(account), "recovery_counterfactual": recovery,
               "within_G1_corridor": .95 <= ratio <= 1.10}
        income = rewards(level)
        row["progression_after_clear"] = advance(account, level, levels[min(index + 1, len(levels) - 1)], income)
        for key in cumulative:
            cumulative[key] += income[key]
        rows.append(row)
    return {"schema_version": 1, "assumptions": {"first_clear_stars": 3, "repeat_farming_in_main_path": False,
            "weapon_cap": 50, "strategy": campaign.ACTIVE_WEAPON_STRATEGY,
            "rewards": "full authored kills + first-clear gold; normalized run_xp_budget; no gold-rush/dynamic-summon/premium bonuses",
            "conditional": "all 99 first clears assumed 3-star; no runtime win claim; farming is counterfactual on a copy of the account",
            "repeat_stars": "zero after an already 3-star clear", "repeat_xp": "existing repeat_clear_xp_mult, no first-clear bonus"},
            "first_R_below_0_95": first_below, "rows": rows,
            "failures": [row["level"] for row in rows if not row["within_G1_corridor"]]}


def render(payload: dict) -> str:
    lines = ["状态：离线条件模拟，不代表实际3★通关；未改数据。", "", "# T3 进度闭环", "",
             "只用假定3★首通，金币按逐敌四舍五入；非Boss波support不计。", 
             "主路径不刷关；恢复次数是独立副本反事实，不向后续99关注入刷取资源。",
             "不计动态召唤、金币卡、付费助推；按现有购买/升级优先级和技能经验成本。",
             "重复3★没有新增星星，只有金币与递减经验。R是显示战力比，不等于已验证胜率。", "",
             f"首次R<0.95：{payload['first_R_below_0_95']}；G1走廊不满足关数：{len(payload['failures'])}/99。", "",
             "|关卡|累计金币(入场前)|当前战力|推荐|R|首通金币|当关购入/升级|回刷至R≥1|", "|---|---:|---:|---:|---:|---:|---|---:|"]
    for row in payload["rows"]:
        progression = row["progression_after_clear"]
        events = [entry["item_id"] for entry in progression["purchases"]]
        events += [f"{entry.get('item', entry.get('skill'))} {entry['from']}→{entry['to']}" for entry in progression["upgrades"]]
        recovery = row["recovery_counterfactual"]
        lines.append(f"|{row['level']:03d}|{row['cumulative_earned_before']['gold']}|{row['power']}|{row['recommended']}|{row['R']:.4f}|{progression['income']['gold']}|{'; '.join(events) or '无'}|{recovery.get('repeat_3star_runs') if recovery.get('recovered') else '不可恢复/未收敛'}|")
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
