#!/usr/bin/env python3
"""Audit campaign difficulty against a resource-constrained free build.

This is deliberately independent from the displayed recommended-power scale.
It advances one deterministic free account through the 99 first clears, spends
only gold / XP / stars already earned, then estimates how far each wave can
push before the current build clears it.  The checked-in CSV is a baseline for
the next balance pass; this tool does not mutate levels, economy or power data.

The fixture is intentionally conservative and reproducible:
* normal first clears, two stars, no challenge rewards and no repeat farming;
* star weapons follow the next chapter's modal weakness;
* loadouts use the same matchup-aware power pipeline as the game UI;
* gold prioritizes the next encounter's weapon with a capped switch catch-up;
* XP is spent round-robin on a physical clear/control package and signature;
* the checked-in comparison report preserves the former capacity-only strategy.

Front-line grades mirror the owner-approved semantics:
* easy: nobody reaches 50% of the route;
* light_pressure: reaches 50%, base remains full;
* pressure: reaches the attack zone and damages the base without a breach;
* high: an enemy reaches the base edge, but the build still clears in time;
* unwinnable: the base is destroyed or the analytical clear exceeds its cap.
"""
from __future__ import annotations

import argparse
import csv
import io
import json
import hashlib
import math
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
REPORT = ROOT / "design" / "audits" / "campaign_frontline_baseline.csv"
TARGET_REPORT = ROOT / "design" / "audits" / "campaign_frontline_target_delta.csv"
BUILD_REPORT = ROOT / "design" / "audits" / "campaign_progression_fixture_builds.json"
WEAPON_REPORT = ROOT / "design" / "audits" / "campaign_progression_weapon_strategy_v2.csv"
MANIFEST_REPORT = ROOT / "design" / "audits" / "campaign_frontline_audit_manifest.json"
TARGET_SOURCE = DATA / "campaign_pacing_targets.json"
FIXTURE_SOURCE = DATA / "campaign_progression_fixture.json"
sys.path.insert(0, str(ROOT / "tools"))

import simulate_balance as sim  # noqa: E402
from power_ruler_model import clear_time_cap, power_for_build, survival_multiplier  # noqa: E402

SPAWN_Y = 190.0
BASE_Y = 1500.0
ROUTE_DISTANCE = BASE_Y - SPAWN_Y
DEFAULT_ATTACK_INTERVAL = 1.35
SLOT_TABLE = {
    "character": "characters",
    "weapon": "weapons",
    "armor": "armors",
    "chip": "chips",
    "pet": "pets",
}
GRADE_ZH = {
    "easy": "轻松",
    "light_pressure": "略有压力",
    "pressure": "压力",
    "high": "难度高",
    "unwinnable": "不可胜",
}


def load(name: str):
    return json.loads((DATA / f"{name}.json").read_text(encoding="utf-8"))


TABLES = {name: load(name) for name in (
    "levels", "characters", "weapons", "armors", "chips", "pets",
    "skills", "zombies", "bosses", "economy",
)}
TARGETS = json.loads(TARGET_SOURCE.read_text(encoding="utf-8"))
FIXTURE = json.loads(FIXTURE_SOURCE.read_text(encoding="utf-8"))
ACTIVE_WEAPON_STRATEGY = str(FIXTURE["active_weapon_strategy"])
LEGACY_WEAPON_STRATEGY = "legacy_capacity_v1"
CORE_SKILLS = tuple(str(value) for value in FIXTURE["xp_upgrade_order"])
WEAPON_ORDER = tuple(str(value) for value in TABLES["weapons"])


@dataclass
class Account:
    gold: int = 0
    xp: int = 0
    stars: int = 0
    owned: dict[str, set[str]] = field(default_factory=lambda: {
        "character": {"vanguard"}, "weapon": {"weapon_autocannon"},
        "armor": set(), "chip": set(), "pet": set(),
    })
    levels: dict[str, int] = field(default_factory=lambda: {
        "vanguard": 1, "weapon_autocannon": 1,
    })
    skills: dict[str, int] = field(default_factory=dict)
    signature: int = 0

    @classmethod
    def from_fixture(cls) -> "Account":
        row = FIXTURE["initial_account"]
        return cls(
            gold=int(row.get("gold", 0)),
            xp=int(row.get("xp", 0)),
            stars=int(row.get("stars", 0)),
            owned={slot: set(values) for slot, values in row["owned"].items()},
            levels={str(key): int(value) for key, value in row["levels"].items()},
            skills={str(key): int(value) for key, value in row.get("skills", {}).items()},
            signature=int(row.get("signature_level", 0)),
        )


def upgrade_cost(row: dict, current_level: int) -> int:
    base = int(row.get("cost_base_gold", 0))
    k = float(TABLES["economy"].get("upgrade_cost_linear_k", 0.7))
    return int(round(base * (1.0 + k * max(current_level - 1, 0))))


def weapon_strategy(strategy_id: str) -> dict:
    strategies = FIXTURE.get("weapon_strategies", {})
    if strategy_id not in strategies:
        raise SystemExit(f"unknown campaign progression weapon strategy: {strategy_id}")
    return dict(strategies[strategy_id])


def chapter_modal_weakness(chapter: int) -> str:
    """Return the chapter weakness mode; authored level order breaks ties."""
    counts: dict[str, int] = {}
    first_seen: dict[str, int] = {}
    for index, level in enumerate(TABLES["levels"]):
        if int(level.get("chapter", 0)) != chapter:
            continue
        element = str(level.get("primary_weakness", "physical"))
        counts[element] = counts.get(element, 0) + 1
        first_seen.setdefault(element, index)
    if not counts:
        return "physical"
    return min(counts, key=lambda value: (-counts[value], first_seen[value]))


def purchase_target_after_level(level: dict, strategy_id: str) -> tuple[int, str]:
    strategy = weapon_strategy(strategy_id)
    if strategy.get("purchase_mode") != "next_chapter_modal_weakness":
        return int(level.get("chapter", 1)), ""
    current = int(level.get("chapter", 1))
    target = min(current + 1, max(int(row.get("chapter", 1)) for row in TABLES["levels"]))
    return target, chapter_modal_weakness(target)


def _unlock(account: Account, slot: str, item_id: str, cost: int) -> dict:
    account.stars -= cost
    account.owned[slot].add(item_id)
    account.levels[item_id] = 1
    return {"slot": slot, "item_id": item_id, "star_cost": cost}


def buy_available(account: Account, cleared_level: dict, strategy_id: str) -> list[dict]:
    """Purchase deterministic free progression items under the selected strategy."""
    strategy = weapon_strategy(strategy_id)
    events: list[dict] = []
    if strategy.get("purchase_mode") == "fixed_order":
        for entry in strategy.get("purchase_order", []):
            slot, item_id = str(entry["slot"]), str(entry["item_id"])
            if item_id in account.owned[slot]:
                continue
            row = TABLES[SLOT_TABLE[slot]][item_id]
            cost = int(row.get("unlock_cost_star", 0))
            if account.stars < cost:
                return events
            events.append(_unlock(account, slot, item_id, cost))
        return events

    if strategy.get("purchase_mode") != "next_chapter_modal_weakness":
        raise SystemExit(f"unsupported purchase mode for {strategy_id}")
    target_chapter, target_element = purchase_target_after_level(cleared_level, strategy_id)
    pool = strategy["star_weapon_pool"]
    minimum = int(pool.get("minimum_star_cost", 1))
    maximum = int(pool.get("maximum_star_cost", 999))
    matching: list[tuple[int, int, str]] = []
    for index, (item_id, row) in enumerate(TABLES["weapons"].items()):
        cost = int(row.get("unlock_cost_star", 0))
        if item_id in account.owned["weapon"] or not minimum <= cost <= maximum:
            continue
        if str(row.get("element", "physical")) != target_element:
            continue
        matching.append((cost, index, str(item_id)))
    matching.sort()
    if matching:
        cost, _index, item_id = matching[0]
        # Holding stars for the next useful element weapon prevents the fixture
        # from spending its campaign currency on an unrelated catalogue item.
        if account.stars >= cost:
            event = _unlock(account, "weapon", item_id, cost)
            event.update({"target_chapter": target_chapter, "target_weakness": target_element})
            events.append(event)
        return events

    for entry in strategy.get("non_weapon_purchase_order", []):
        slot, item_id = str(entry["slot"]), str(entry["item_id"])
        if item_id in account.owned[slot]:
            continue
        row = TABLES[SLOT_TABLE[slot]][item_id]
        cost = int(row.get("unlock_cost_star", 0))
        if account.stars < cost:
            return events
        event = _unlock(account, slot, item_id, cost)
        event.update({"target_chapter": target_chapter, "target_weakness": target_element})
        events.append(event)
    return events


def level_weight(slot: str, item_id: str) -> float:
    weights = FIXTURE["gold_upgrade_weights"]
    if item_id in weights:
        return float(weights[item_id])
    return float(weights[slot])


def _buy_gold_upgrade(account: Account, slot: str, item_id: str) -> int:
    row = TABLES[SLOT_TABLE[slot]][item_id]
    level = account.levels[item_id]
    if level >= int(row.get("max_level", 1)):
        return 0
    cost = upgrade_cost(row, level)
    if cost > account.gold:
        return 0
    account.gold -= cost
    account.levels[item_id] += 1
    return cost


def spend_gold(
    account: Account,
    strategy_id: str,
    earned_gold: int,
    current_weapon: str,
    preferred_next_weapon: str,
) -> dict:
    """Balanced free progression using exact runtime upgrade prices."""
    priority_spent = 0
    priority_upgrades = 0
    strategy = weapon_strategy(strategy_id)
    gold_rule = strategy.get("gold_upgrade", {}) or {}
    if preferred_next_weapon and preferred_next_weapon in account.owned["weapon"]:
        if preferred_next_weapon != current_weapon:
            ceiling = int(account.levels.get(current_weapon, 1))
            budget = int(math.floor(max(earned_gold, 0) * float(gold_rule.get("switch_catch_up_max_gold_ratio", 0.0))))
            while account.levels[preferred_next_weapon] < ceiling:
                row = TABLES["weapons"][preferred_next_weapon]
                cost = upgrade_cost(row, account.levels[preferred_next_weapon])
                if priority_spent + cost > budget:
                    break
                paid = _buy_gold_upgrade(account, "weapon", preferred_next_weapon)
                if paid <= 0:
                    break
                priority_spent += paid
                priority_upgrades += 1
        else:
            for _unused in range(int(gold_rule.get("same_weapon_priority_upgrades_per_clear", 0))):
                paid = _buy_gold_upgrade(account, "weapon", preferred_next_weapon)
                if paid <= 0:
                    break
                priority_spent += paid
                priority_upgrades += 1
    while True:
        candidates: list[tuple[float, int, str, str]] = []
        for slot, ids in account.owned.items():
            table = TABLES[SLOT_TABLE[slot]]
            for item_id in ids:
                row = table[item_id]
                level = account.levels[item_id]
                maximum = int(row.get("max_level", 1))
                if level >= maximum:
                    continue
                cost = upgrade_cost(row, level)
                if cost > account.gold:
                    continue
                # Lowest normalized level wins; weight keeps offense slightly
                # ahead without starving survival or the graduation weapon.
                progress = level / max(maximum, 1)
                priority = level_weight(slot, item_id) / (0.08 + progress)
                candidates.append((-priority, cost, slot, item_id))
        if not candidates:
            break
        _, cost, _slot, item_id = min(candidates)
        account.gold -= cost
        account.levels[item_id] += 1
    return {
        "preferred_next_weapon": preferred_next_weapon,
        "priority_gold_spent": priority_spent,
        "priority_upgrades": priority_upgrades,
    }


def spend_xp(account: Account) -> None:
    base_costs = list(TABLES["economy"].get("skill_base_xp_costs", []))
    sig_costs = list(TABLES["economy"].get("sig_skill_xp_costs", []))
    while True:
        bought = False
        minimum = min([account.signature] + [account.skills.get(k, 0) for k in CORE_SKILLS if k != "signature"])
        for skill_id in CORE_SKILLS:
            level = account.signature if skill_id == "signature" else account.skills.get(skill_id, 0)
            if level > minimum or level >= 5:
                continue
            costs = sig_costs if skill_id == "signature" else base_costs
            if level >= len(costs) or account.xp < int(costs[level]):
                continue
            account.xp -= int(costs[level])
            if skill_id == "signature":
                account.signature += 1
            else:
                account.skills[skill_id] = level + 1
            bought = True
            break
        if not bought:
            return


def build_for(
    account: Account,
    level: dict,
    fire_rate_profile: str = "control",
    strategy_id: str = ACTIVE_WEAPON_STRATEGY,
) -> tuple[dict, dict]:
    contract = level.get("clear_requirement", {}).get("power_contract", {})
    base = {
        "character": "vanguard",
        "character_level": account.levels["vanguard"],
        "armor": "armor_kevlar" if "armor_kevlar" in account.owned["armor"] else "",
        "armor_level": account.levels.get("armor_kevlar", 1),
        "chip": "chip_attack" if "chip_attack" in account.owned["chip"] else "",
        "chip_level": account.levels.get("chip_attack", 1),
        "pet": "pet_turret_drone" if "pet_turret_drone" in account.owned["pet"] else "",
        "pet_level": account.levels.get("pet_turret_drone", 1),
        "signature_level": account.signature,
        "skill_base_levels": dict(account.skills),
    }
    selection = weapon_strategy(strategy_id)["selection"]
    if selection.get("candidates") == "all_owned_weapons":
        choices = [weapon_id for weapon_id in WEAPON_ORDER if weapon_id in account.owned["weapon"]]
    else:
        choices = [
            str(weapon_id) for weapon_id in selection.get("candidates", [])
            if str(weapon_id) in account.owned["weapon"]
        ]
    scored: list[tuple[float, int, dict, dict]] = []
    for choice_index, weapon_id in enumerate(choices):
        candidate = {**base, "weapon": weapon_id, "weapon_level": account.levels[weapon_id]}
        # Keep the checked-in control fixture byte-for-byte stable.  Laboratory
        # reports opt into A/B explicitly and share this exact progression build.
        if fire_rate_profile != "control":
            candidate["fire_rate_profile"] = fire_rate_profile
        result = power_for_build(
            level, contract, candidate,
            TABLES["characters"], TABLES["weapons"], TABLES["armors"],
            TABLES["chips"], TABLES["pets"], TABLES["skills"],
            TABLES["bosses"], TABLES["economy"],
        )
        if selection.get("method") == "power_for_build":
            score = float(result["power"])
        elif selection.get("method") == "weighted_capacity":
            boss_weight = (
                float(selection["boss_capacity_weight_if_present"])
                if any("boss" in wave for wave in level.get("waves", []))
                else float(selection["boss_capacity_weight_otherwise"])
            )
            score = result["capacities"]["crowd"] * (1.0 - boss_weight) + result["capacities"]["boss"] * boss_weight
        else:
            raise SystemExit(f"unsupported weapon selection method for {strategy_id}")
        scored.append((score, -choice_index, candidate, result))
    if not scored:
        raise SystemExit(f"campaign progression fixture owns no selectable weapon for {strategy_id}")
    _, _tie_break, build, result = max(scored, key=lambda row: (row[0], row[1]))
    return build, result


def skill_effect(skill_id: str, level: int) -> dict:
    if level <= 0:
        return {}
    rows = TABLES["skills"].get(skill_id, {}).get("levels", [])
    for row in rows:
        if int(row.get("lv", 0)) == level:
            return dict(row.get("effect", {}))
    return {}


def travel_time(row: dict, projected: dict[str, int], boss: bool, attack_line_y: float = BASE_Y) -> float:
    speed = max(float(row.get("speed", 20.0)) * float(TABLES["economy"].get("ENEMY_SPEED_MULT", 0.492)), 0.1)
    if boss:
        speed *= float(TABLES["economy"].get("BOSS_SPEED_MULT", 1.5))
    distance = max(attack_line_y - SPAWN_Y, 1.0)
    slow_effect = skill_effect("skill_slow_field", int(projected.get("skill_slow_field", 0)))
    slow = max(float(slow_effect.get("slow", 0.0)), 0.0)
    y_min = float(slow_effect.get("y_min", BASE_Y))
    if slow <= 0.0 or y_min >= attack_line_y:
        return distance / speed
    slow = min(slow, 0.40 if boss else 0.80)
    normal_distance = max(min(y_min, attack_line_y) - SPAWN_Y, 0.0)
    slow_distance = max(attack_line_y - max(y_min, SPAWN_Y), 0.0)
    return normal_distance / speed + slow_distance / max(speed * (1.0 - slow), 0.1)


def boss_attack_stats(row: dict) -> tuple[float, float, float, float]:
    mechanic = str(row.get("mechanic", ""))
    params = row.get("mechanic_params", {}) or {}
    profile = params.get("base_attack_profile", {}) or {}
    mult, interval = 1.0, DEFAULT_ATTACK_INTERVAL
    if mechanic in {"runner", "low_profile", "leap", "charge", "phase", "phase_shift"}:
        mult, interval = 0.72, 0.82
    elif mechanic in {"tank", "armor", "armor_break", "juggernaut", "shield_aura", "ward", "multi_phase"}:
        mult, interval = 1.38, 1.72
    elif mechanic in {"explode_on_death", "phase_burn"}:
        mult, interval = 1.18, 1.46
    elif mechanic in {"ranged_spit", "toxic_cloud", "regenerate", "spawn_minions"}:
        mult, interval = 0.86, 1.12
    elif mechanic in {"buff_aura", "summon"}:
        mult, interval = 0.76, 1.05
    interval = float(params.get("base_attack_interval", interval + 0.28))
    damage = float(params.get("base_attack_damage", round(10.0 * float(row.get("bd_coef", 4.0)) * mult * 1.35)))
    line_y = BASE_Y + float(profile.get("line_offset", -80.0))
    first_delay = max(float(profile.get("first_attack_delay", 0.2)), 0.0)
    return damage, interval, line_y, first_delay


def mob_hp(level: dict, row: dict, wave: dict) -> float:
    wave_no = sim.wave_number(wave)
    return (
        float(level.get("base_hp_ref", 50.0))
        * float(row.get("hp_coef", 1.0))
        * float(level.get("difficulty_coef", 1.0))
        * sim.wave_hp_coef(wave)
        * sim.late_wave_hp_bonus(TABLES["economy"], wave_no, level_no=sim.level_number(level), card_picks=int(level.get("target_card_picks", 4)))
    )


def base_hp(level: dict, build: dict, projected: dict[str, int]) -> float:
    boss_level = any("boss" in wave for wave in level.get("waves", []))
    cushion = sim.boss_base_hp_cushion(TABLES["economy"], sim.level_number(level)) if boss_level else 1.0
    survival = survival_multiplier(
        TABLES["characters"][build["character"]], build["character_level"],
        TABLES["weapons"][build["weapon"]],
        TABLES["armors"].get(build["armor"]), build["armor_level"],
        TABLES["chips"].get(build["chip"]), build["chip_level"],
        TABLES["pets"].get(build["pet"]), build["pet_level"],
    )
    barrier = skill_effect("skill_barrier", int(projected.get("skill_barrier", 0)))
    return float(level.get("base_hp_ref", 100.0)) * cushion * survival * (1.0 + float(barrier.get("base_hp_mult", 0.0)))


def units_for_wave(level: dict, wave: dict) -> list[dict]:
    wave_no = sim.wave_number(wave)
    count_mult = sim.late_wave_count_mult(TABLES["economy"], wave_no, sim.level_number(level))
    units: list[dict] = []
    for group in list(wave.get("spawns", [])) + list(wave.get("support", [])):
        row = TABLES["zombies"].get(str(group.get("type", "")), {})
        count = int(round(int(group.get("count", 0)) * count_mult))
        interval = float(group.get("interval", 0.8))
        for index in range(count):
            units.append({"arrival": index * interval, "boss": False, "row": row, "hp": mob_hp(level, row, wave)})
    for entry in sim.runtime_boss_entries(level, wave):
        row = TABLES["bosses"][entry["type"]]
        units.append({"arrival": 0.0, "boss": True, "row": row, "hp": sim.boss_hp_for_entry(level, row, TABLES["economy"], wave_no)})
    return sorted(units, key=lambda unit: (unit["arrival"], not unit["boss"]))


def simulate_level(
    account: Account,
    level: dict,
    fire_rate_profile: str = "control",
    strategy_id: str = ACTIVE_WEAPON_STRATEGY,
) -> dict:
    build, power = build_for(account, level, fire_rate_profile, strategy_id)
    projected = power["projected_skills"]
    ruler = TABLES["economy"].get("power_ruler", {}) or {}
    crowd_dps = max(float(power["capacities"]["crowd"]) * float(ruler.get("crowd_dps_per_capacity", 75.0)), 1.0)
    boss_dps = max(float(power["capacities"]["boss"]) * float(ruler.get("boss_dps_per_capacity", 206.98)), 1.0)
    maximum_hp = base_hp(level, build, projected)
    remaining_hp = maximum_hp
    max_progress = 0.0
    edge_reached = False
    elapsed = 0.0
    for wave in level.get("waves", []):
        server_free = 0.0
        for unit in units_for_wave(level, wave):
            arrival = float(unit["arrival"])
            row, is_boss = unit["row"], bool(unit["boss"])
            dps = boss_dps if is_boss else crowd_dps
            start = max(arrival, server_free)
            kill_end = start + float(unit["hp"]) / dps
            if is_boss:
                damage, interval, line_y, first_delay = boss_attack_stats(row)
                to_line = travel_time(row, projected, True, line_y)
                line_at = arrival + to_line
                if kill_end >= line_at:
                    max_progress = max(max_progress, (line_y - SPAWN_Y) / ROUTE_DISTANCE)
                    active = max(kill_end - line_at - first_delay, 0.0)
                    attacks = 1 + int(active / max(interval, 0.1)) if kill_end >= line_at + first_delay else 0
                    remaining_hp -= attacks * damage
                else:
                    max_progress = max(max_progress, (kill_end - arrival) / max(travel_time(row, projected, True, BASE_Y), 0.1))
                server_free = kill_end
            else:
                route_time = travel_time(row, projected, False, BASE_Y)
                breach_at = arrival + route_time
                exit_at = min(kill_end, breach_at)
                progress = min(max((exit_at - arrival) / max(route_time, 0.1), 0.0), 1.0)
                max_progress = max(max_progress, progress)
                if kill_end >= breach_at:
                    edge_reached = True
                    remaining_hp -= 10.0 * float(row.get("bd_coef", 1.0))
                server_free = exit_at
        elapsed += server_free
    max_progress = min(max_progress, 1.0)
    hp_ratio = max(remaining_hp / max(maximum_hp, 1.0), 0.0)
    cap = clear_time_cap(sim.level_number(level))
    timed_out = elapsed > cap
    cleared = hp_ratio > 0.0 and not timed_out
    if not cleared:
        grade = "unwinnable"
        unwinnable_reason = "base_destroyed" if hp_ratio <= 0.0 else "clear_timeout"
    elif edge_reached:
        grade = "high"
        unwinnable_reason = ""
    elif hp_ratio < 0.999 and max_progress >= 0.80:
        grade = "pressure"
        unwinnable_reason = ""
    elif max_progress >= 0.50:
        grade = "light_pressure"
        unwinnable_reason = ""
    else:
        grade = "easy"
        unwinnable_reason = ""
    return {
        "level": sim.level_number(level), "chapter": int(level.get("chapter", 1)),
        "grade": grade, "max_progress": max_progress, "base_hp_ratio": hp_ratio,
        "cleared": cleared, "edge_reached": edge_reached, "timed_out": timed_out,
        "unwinnable_reason": unwinnable_reason, "clear_time_seconds": elapsed,
        "clear_time_cap_seconds": cap,
        "weapon": build["weapon"], "character_level": build["character_level"],
        "weapon_level": build["weapon_level"], "armor_level": build["armor_level"] if build["armor"] else 0,
        "chip_level": build["chip_level"] if build["chip"] else 0,
        "pet_level": build["pet_level"] if build["pet"] else 0,
        "signature_level": build["signature_level"],
        "gold_before": account.gold, "xp_before": account.xp, "stars_before": account.stars,
        "crowd_dps": crowd_dps, "boss_dps": boss_dps,
        "effective_power": int(round(float(power["power"]))),
        "build": build, "projected_skills": projected,
    }


def earned_resources(level: dict) -> tuple[int, int]:
    number = sim.level_number(level)
    gold_per = float(TABLES["economy"].get("gold_drop_base", 5.0)) + float(TABLES["economy"].get("gold_drop_per_level", 0.6)) * number
    gold = int(level.get("first_clear_reward", {}).get("gold", 0))
    authored_xp = 0
    runtime_extra_xp = 0
    for wave in level.get("waves", []):
        wave_no = sim.wave_number(wave)
        count_mult = sim.late_wave_count_mult(TABLES["economy"], wave_no, number)
        for group in list(wave.get("spawns", [])) + list(wave.get("support", [])):
            row = TABLES["zombies"].get(str(group.get("type", "")), {})
            count = int(round(int(group.get("count", 0)) * count_mult))
            gold += int(round(count * gold_per * float(row.get("gold_coef", 1.0)) * float(level.get("reward_gold_mult", 1.0))))
            authored_xp += count * int(row.get("run_xp", 1))
        if "boss" in wave:
            row = TABLES["bosses"].get(str(wave.get("boss", "")), {})
            gold += int(round(gold_per * float(row.get("gold_coef", 1.0)) * float(level.get("reward_gold_mult", 1.0))))
            authored_xp += int(row.get("run_xp", 1))
        for entry in sim.runtime_boss_entries(level, wave):
            if bool(entry.get("primary", False)):
                continue
            row = TABLES["bosses"].get(entry["type"], {})
            gold += int(round(gold_per * float(row.get("gold_coef", 1.0)) * float(level.get("reward_gold_mult", 1.0))))
            runtime_extra_xp += int(row.get("run_xp", 1))
    xp = int(level.get("run_xp_budget", 0)) or authored_xp
    return gold, xp + runtime_extra_xp


FIELDS = (
    "level", "chapter", "grade", "grade_zh", "max_progress_pct", "base_hp_pct",
    "cleared", "edge_reached", "timed_out", "unwinnable_reason",
    "clear_time_seconds", "clear_time_cap_seconds",
    "weapon", "character_level", "weapon_level", "armor_level", "chip_level",
    "pet_level", "signature_level", "gold_before", "xp_before", "stars_before",
    "crowd_dps", "boss_dps",
)

TARGET_FIELDS = (
    "level", "chapter", "current_grade", "target_grade", "grade_delta_steps",
    "current_progress_pct", "target_progress_pct", "progress_delta_pct",
    "current_base_hp_pct", "target_base_hp_pct", "base_hp_delta_pct",
    "cleared", "unwinnable_reason", "target_frozen",
)

WEAPON_COMPARISON_FIELDS = (
    "level", "chapter", "next_chapter_target", "next_chapter_weakness",
    "legacy_weapon", "legacy_weapon_level", "legacy_effective_power",
    "v2_weapon", "v2_weapon_level", "v2_effective_power",
    "weapon_changed", "level_delta", "v2_purchases_after_clear",
    "v2_preferred_next_weapon", "v2_priority_gold_spent",
)


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def target_rows() -> dict[int, dict]:
    result: dict[int, dict] = {}
    expected_quotas = TARGETS["chapter_quotas"]
    level_number = 1
    for chapter in range(1, 11):
        grades = list(TARGETS["chapter_level_targets"][str(chapter)])
        expected_count = 9 if chapter == 10 else 10
        if len(grades) != expected_count:
            raise SystemExit(f"chapter {chapter} target sequence must contain {expected_count} grades")
        counts = {grade: grades.count(grade) for grade in TARGETS["grade_order"]}
        if counts != {key: int(value) for key, value in expected_quotas[str(chapter)].items()}:
            raise SystemExit(f"chapter {chapter} target sequence does not match quota: {counts}")
        for grade in grades:
            center = TARGETS["target_bands"][grade]["center"]
            result[level_number] = {
                "level": level_number,
                "chapter": chapter,
                "grade": grade,
                "progress_pct": float(center["progress_pct"]),
                "base_hp_pct": float(center["base_hp_pct"]),
            }
            level_number += 1
    if level_number != 100:
        raise SystemExit("campaign pacing target sequence must cover level_001..099 exactly")
    return result


def generate_rows(
    fire_rate_profile: str = "control",
    strategy_id: str = ACTIVE_WEAPON_STRATEGY,
) -> tuple[list[dict], list[dict]]:
    account = Account.from_fixture()
    rows: list[dict] = []
    builds: list[dict] = []
    for level_index, level in enumerate(TABLES["levels"]):
        result = simulate_level(account, level, fire_rate_profile, strategy_id)
        row = {
            **{
                key: result[key] for key in result
                if key not in {"max_progress", "base_hp_ratio", "build", "projected_skills"}
            },
            "grade_zh": GRADE_ZH[result["grade"]],
            "max_progress_pct": round(result["max_progress"] * 100.0, 2),
            "base_hp_pct": round(result["base_hp_ratio"] * 100.0, 2),
            "clear_time_seconds": round(result["clear_time_seconds"], 3),
            "clear_time_cap_seconds": round(result["clear_time_cap_seconds"], 3),
            "crowd_dps": round(result["crowd_dps"], 2),
            "boss_dps": round(result["boss_dps"], 2),
        }
        rows.append(row)
        build_row = {
            "level_id": str(level["id"]),
            "level": result["level"],
            "card_seeds": list(FIXTURE["runtime_probe"]["fixed_card_seeds"]),
            "build": result["build"],
            "projected_skills": result["projected_skills"],
            "resources_before": {
                "gold": account.gold, "xp": account.xp, "stars": account.stars,
            },
        }
        builds.append(build_row)
        gold, xp = earned_resources(level)
        account.gold += gold
        account.xp += xp
        account.stars += int(FIXTURE["assumptions"]["stars_per_clear"])
        purchases = buy_available(account, level, strategy_id)
        next_level = TABLES["levels"][level_index + 1] if level_index + 1 < len(TABLES["levels"]) else level
        preferred_next, _preferred_power = build_for(account, next_level, fire_rate_profile, strategy_id)
        gold_result = spend_gold(
            account,
            strategy_id,
            gold,
            str(result["weapon"]),
            str(preferred_next["weapon"]),
        )
        spend_xp(account)
        target_chapter, target_weakness = purchase_target_after_level(level, strategy_id)
        progression = {
            "strategy_id": strategy_id,
            "gold_earned": gold,
            "xp_earned": xp,
            "star_weapon_target_chapter": target_chapter,
            "star_weapon_target_weakness": target_weakness,
            "purchases": purchases,
            **gold_result,
            "resources_after": {
                "gold": account.gold, "xp": account.xp, "stars": account.stars,
            },
        }
        build_row["progression_after_clear"] = progression
        row["strategy_id"] = strategy_id
        row["purchases_after_clear"] = ";".join(str(event["item_id"]) for event in purchases)
        row["star_weapon_target_chapter"] = target_chapter
        row["star_weapon_target_weakness"] = target_weakness
        row["preferred_next_weapon"] = gold_result["preferred_next_weapon"]
        row["priority_gold_spent"] = gold_result["priority_gold_spent"]
    return rows, builds


def render_csv(rows: list[dict]) -> str:
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=FIELDS, lineterminator="\n")
    writer.writeheader()
    writer.writerows({key: row.get(key, "") for key in FIELDS} for row in rows)
    return stream.getvalue()


def render_target_csv(rows: list[dict]) -> str:
    targets = target_rows()
    grade_order = list(TARGETS["grade_order"])
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=TARGET_FIELDS, lineterminator="\n")
    writer.writeheader()
    for row in rows:
        target = targets[row["level"]]
        current_grade = row["grade"]
        grade_delta = ""
        if current_grade in grade_order:
            grade_delta = grade_order.index(current_grade) - grade_order.index(target["grade"])
        writer.writerow({
            "level": row["level"],
            "chapter": row["chapter"],
            "current_grade": current_grade,
            "target_grade": target["grade"],
            "grade_delta_steps": grade_delta,
            "current_progress_pct": row["max_progress_pct"],
            "target_progress_pct": target["progress_pct"],
            "progress_delta_pct": round(row["max_progress_pct"] - target["progress_pct"], 2),
            "current_base_hp_pct": row["base_hp_pct"],
            "target_base_hp_pct": target["base_hp_pct"],
            "base_hp_delta_pct": round(row["base_hp_pct"] - target["base_hp_pct"], 2),
            "cleared": row["cleared"],
            "unwinnable_reason": row["unwinnable_reason"],
            "target_frozen": bool(TARGETS["frozen"]),
        })
    return stream.getvalue()


def render_weapon_comparison(legacy_rows: list[dict], v2_rows: list[dict]) -> str:
    if len(legacy_rows) != len(v2_rows):
        raise SystemExit("weapon strategy comparison row counts differ")
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=WEAPON_COMPARISON_FIELDS, lineterminator="\n")
    writer.writeheader()
    for legacy, current in zip(legacy_rows, v2_rows):
        writer.writerow({
            "level": current["level"],
            "chapter": current["chapter"],
            "next_chapter_target": current.get("star_weapon_target_chapter", ""),
            "next_chapter_weakness": current.get("star_weapon_target_weakness", ""),
            "legacy_weapon": legacy["weapon"],
            "legacy_weapon_level": legacy["weapon_level"],
            "legacy_effective_power": legacy.get("effective_power", ""),
            "v2_weapon": current["weapon"],
            "v2_weapon_level": current["weapon_level"],
            "v2_effective_power": current.get("effective_power", ""),
            "weapon_changed": legacy["weapon"] != current["weapon"],
            "level_delta": int(current["weapon_level"]) - int(legacy["weapon_level"]),
            "v2_purchases_after_clear": current.get("purchases_after_clear", ""),
            "v2_preferred_next_weapon": current.get("preferred_next_weapon", ""),
            "v2_priority_gold_spent": current.get("priority_gold_spent", 0),
        })
    return stream.getvalue()


def render_builds(builds: list[dict]) -> str:
    payload = {
        "schema_version": 1,
        "fixture_id": FIXTURE["id"],
        "weapon_strategy_id": ACTIVE_WEAPON_STRATEGY,
        "fixture_source": str(FIXTURE_SOURCE.relative_to(ROOT)),
        "fixture_sha256": _sha256(FIXTURE_SOURCE),
        "levels_sha256": _sha256(DATA / "levels.json"),
        "calibration_levels": list(FIXTURE["runtime_probe"]["calibration_levels"]),
        "rows": builds,
    }
    return json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def render_manifest(rows: list[dict]) -> str:
    counts = {grade: 0 for grade in GRADE_ZH}
    for row in rows:
        counts[row["grade"]] += 1
    payload = {
        "schema_version": 1,
        "levels_path": "data/levels.json",
        "levels_sha256": _sha256(DATA / "levels.json"),
        "pacing_targets_path": str(TARGET_SOURCE.relative_to(ROOT)),
        "pacing_targets_sha256": _sha256(TARGET_SOURCE),
        "pacing_targets_frozen": bool(TARGETS["frozen"]),
        "progression_fixture_path": str(FIXTURE_SOURCE.relative_to(ROOT)),
        "progression_fixture_sha256": _sha256(FIXTURE_SOURCE),
        "weapon_strategy_id": ACTIVE_WEAPON_STRATEGY,
        "row_count": len(rows),
        "current_grade_counts": counts,
        "reports": [
            str(REPORT.relative_to(ROOT)),
            str(TARGET_REPORT.relative_to(ROOT)),
            str(BUILD_REPORT.relative_to(ROOT)),
            str(WEAPON_REPORT.relative_to(ROOT)),
        ],
    }
    return json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    rows, builds = generate_rows(strategy_id=ACTIVE_WEAPON_STRATEGY)
    legacy_rows, _legacy_builds = generate_rows(strategy_id=LEGACY_WEAPON_STRATEGY)
    if len(rows) != 99 or [row["level"] for row in rows] != list(range(1, 100)):
        raise SystemExit("campaign frontline audit must cover level_001..099 exactly")
    outputs = {
        REPORT: render_csv(rows),
        TARGET_REPORT: render_target_csv(rows),
        BUILD_REPORT: render_builds(builds),
        WEAPON_REPORT: render_weapon_comparison(legacy_rows, rows),
        MANIFEST_REPORT: render_manifest(rows),
    }
    if args.write:
        REPORT.parent.mkdir(parents=True, exist_ok=True)
        for path, text in outputs.items():
            path.write_text(text, encoding="utf-8")
    if args.check:
        for path, text in outputs.items():
            if not path.is_file() or path.read_text(encoding="utf-8") != text:
                raise SystemExit(
                    f"{path.relative_to(ROOT)} is stale; run tools/audit_campaign_frontline.py --write"
                )
    counts: dict[str, int] = {}
    for row in rows:
        counts[row["grade"]] = counts.get(row["grade"], 0) + 1
    print("Campaign growth/front-line baseline (no level or power mutation)")
    print(f"levels.json sha256={_sha256(DATA / 'levels.json')}")
    print(f"targets frozen={bool(TARGETS['frozen'])}; deltas are report-only")
    print(" ".join(f"{GRADE_ZH[key]}={counts.get(key, 0)}" for key in GRADE_ZH))
    for row in rows:
        print(
            f"level_{row['level']:03d} {row['grade_zh']:<5} "
            f"front={row['max_progress_pct']:>6.2f}% base={row['base_hp_pct']:>6.2f}% "
            f"{row['weapon']} L{row['weapon_level']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
