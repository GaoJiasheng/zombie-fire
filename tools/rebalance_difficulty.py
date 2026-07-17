#!/usr/bin/env python3
from __future__ import annotations

import json
import math
from pathlib import Path

from combat_power_model import estimate_skill_throughput, run_skill_hp_pressure

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
LEVELS_PATH = DATA / "levels.json"
ENV_BY_DECADE = [
    "env_lava_foundry",
    "env_glacier_pass",
    "env_abandoned_factory",
    "env_toxic_biolab",
    "env_storm_substation",
    "env_flooded_subway",
    "env_desert_refinery",
    "env_void_cathedral",
    "env_orbital_ruins",
    "env_apex_core",
]

NAME_PREFIXES = ["城市", "废街", "断桥", "熔炉", "冰港", "电塔", "毒巷", "黑墙", "裂谷", "铁门", "终局"]
NAME_SUFFIXES = ["缺口", "突围", "尸潮", "围城", "死守", "重压", "裂隙", "尖啸", "终战"]

LANES = ["left", "center", "right", "spread"]

BIAS_BY_TAG = {
    "anti_swarm": {"anti_swarm": 1.8, "projectile": 1.2},
    "breach": {"anti_swarm": 1.4, "defense": 1.2, "control": 1.1},
    "fast": {"control": 1.7, "ice": 1.3, "homing": 1.1},
    "tank": {"pierce": 1.7, "anti_armor": 1.4, "execute": 1.2},
    "burst": {"defense": 1.5, "anti_swarm": 1.2},
    "support": {"homing": 1.5, "chain": 1.3, "lightning": 1.1},
    "elite": {"execute": 1.4, "pierce": 1.2},
    "boss": {"execute": 1.6, "pierce": 1.4, "defense": 1.1},
}

INTRO_STAGES = {
    1: "aim_and_first_card",
    2: "split_swarm",
    3: "runner_priority",
    4: "tank_burst",
    5: "first_boss",
}

BASE_WEAPON_DAMAGE = 28.0
CHIP_DAMAGE_MULT = 1.20

DEFAULT_LATE_WAVE_HP_BONUS = {"3": 1.45, "4": 1.85, "5": 2.30}
DEFAULT_LATE_WAVE_COUNT_MULT = {"4": 2.0, "5": 3.0}
DEFAULT_LATE_WAVE_BOSS_HP_BONUS = {"3": 1.30, "4": 1.50, "5": 1.75}
DEFAULT_LATE_WAVE_LEVEL_RAMP = {"start_level": 50, "full_level": 98, "max_mult": 1.80, "curve_power": 1.0, "final_level": 99, "final_mult": 1.20}
DEFAULT_BOSS_HP_LEVEL_BONUS = {"start_level": 20, "multiplier": 2.0}


def load_json(name: str):
    return json.loads((DATA / f"{name}.json").read_text(encoding="utf-8"))


def dump_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")


def wave_number(wave: dict) -> int:
    try:
        return int(wave.get("wave", 0))
    except (TypeError, ValueError):
        return 0


def late_wave_level_ramp(economy: dict, level_no: int) -> float:
    rule = economy.get("late_wave_level_ramp", DEFAULT_LATE_WAVE_LEVEL_RAMP)
    if not isinstance(rule, dict):
        rule = DEFAULT_LATE_WAVE_LEVEL_RAMP
    start_level = float(rule.get("start_level", DEFAULT_LATE_WAVE_LEVEL_RAMP["start_level"]))
    full_level = float(rule.get("full_level", DEFAULT_LATE_WAVE_LEVEL_RAMP["full_level"]))
    max_mult = float(rule.get("max_mult", DEFAULT_LATE_WAVE_LEVEL_RAMP["max_mult"]))
    if float(level_no) < start_level:
        return 1.0
    ramp_mult = max_mult
    if full_level > start_level:
        t = max(0.0, min(1.0, (float(level_no) - start_level) / (full_level - start_level)))
        curve_power = max(0.01, float(rule.get("curve_power", DEFAULT_LATE_WAVE_LEVEL_RAMP["curve_power"])))
        ramp_mult = 1.0 + (max_mult - 1.0) * (t ** curve_power)
    final_level = int(rule.get("final_level", DEFAULT_LATE_WAVE_LEVEL_RAMP["final_level"]))
    if level_no >= final_level:
        ramp_mult *= max(1.0, float(rule.get("final_mult", DEFAULT_LATE_WAVE_LEVEL_RAMP["final_mult"])))
    return ramp_mult


def late_wave_hp_bonus(economy: dict, wave_no: int, boss: bool = False, level_no: int = 0, card_picks: int = 4) -> float:
    key = "late_wave_boss_hp_bonus" if boss else "late_wave_hp_bonus"
    defaults = DEFAULT_LATE_WAVE_BOSS_HP_BONUS if boss else DEFAULT_LATE_WAVE_HP_BONUS
    table = economy.get(key, defaults)
    if not isinstance(table, dict):
        table = defaults
    base = float(table.get(str(wave_no), table.get(wave_no, defaults.get(str(wave_no), 1.0))))
    if wave_no >= 3:
        base *= late_wave_level_ramp(economy, level_no)
        base *= run_skill_hp_pressure(card_picks, economy)
    return base


def late_wave_count_mult(economy: dict, wave_no: int) -> float:
    table = economy.get("late_wave_count_mult", DEFAULT_LATE_WAVE_COUNT_MULT)
    if not isinstance(table, dict):
        table = DEFAULT_LATE_WAVE_COUNT_MULT
    return max(1.0, float(table.get(str(wave_no), table.get(wave_no, DEFAULT_LATE_WAVE_COUNT_MULT.get(str(wave_no), 1.0)))))


def boss_hp_level_bonus(economy: dict, level_no: int) -> float:
    rule = economy.get("boss_hp_level_bonus", DEFAULT_BOSS_HP_LEVEL_BONUS)
    if not isinstance(rule, dict):
        rule = DEFAULT_BOSS_HP_LEVEL_BONUS
    start_level = int(rule.get("start_level", DEFAULT_BOSS_HP_LEVEL_BONUS["start_level"]))
    multiplier = float(rule.get("multiplier", DEFAULT_BOSS_HP_LEVEL_BONUS["multiplier"]))
    return multiplier if level_no >= start_level else 1.0


def base_hp_ref(n: int) -> int:
    return int(round(120 + (n - 1) * (700.0 / 98.0)))


def recommend_level(n: int) -> int:
    return min(50, max(1, int(round(1 + (n - 1) * 49.0 / 98.0))))


def target_pressure_ratio(n: int, boss_level: bool) -> float:
    if n <= 5:
        return [0.28, 0.32, 0.37, 0.43, 0.52][n - 1]
    if n < 90:
        ratio = 0.62 + (n - 6) * (0.93 / 83.0)
    else:
        ratio = 1.65 + (n - 90) * (0.30 / 9.0)
    if boss_level:
        ratio += 0.08
    return ratio


def target_card_picks(n: int) -> int:
    if n <= 5:
        return 2
    if n <= 10:
        return 3
    if n <= 30:
        return 5
    if n <= 65:
        return 6
    return 7


def estimate_skill_mult(n: int) -> float:
    return estimate_skill_throughput(target_card_picks(n))


def estimate_player_dps(characters: dict, weapons: dict, economy: dict, n: int) -> float:
    char = characters["vanguard"]
    weapon = weapons["weapon_autocannon"]
    level = recommend_level(n)
    base_atk = float(char["base_atk"])
    atk_growth = float(char["atk_growth"])
    fire_rate_mod = float(char.get("fire_rate_mod", 1.0))
    base_atk_coef = float(weapon.get("base_atk_coef", 1.0))
    fire_rate = float(weapon.get("fire_rate", 4.0))
    char_atk_mult = (base_atk / 100.0) * (1.0 + atk_growth * 0.45 * (level - 1))
    weapon_dmg_mult = 1.0 + 0.08 * (level - 1)
    weapon_fr_mult = 1.0 + 0.025 * (level - 1)
    base_damage = BASE_WEAPON_DAMAGE * base_atk_coef
    damage = base_damage * char_atk_mult * weapon_dmg_mult * CHIP_DAMAGE_MULT * float(economy.get("PLAYER_SHOT_DAMAGE_MULT", 1.0))
    fr = fire_rate * weapon_fr_mult * float(economy.get("PLAYER_FIRE_RATE_MULT", 0.25)) * fire_rate_mod
    return damage * fr * estimate_skill_mult(n)


def enemy_hp_weight(waves: list[dict], zombies: dict, bosses: dict, economy: dict) -> float:
    total = 0.0
    for wave in waves:
        count_mult = late_wave_count_mult(economy, wave_number(wave))
        for spawn in wave.get("spawns", []):
            total += float(zombies[spawn["type"]].get("hp_coef", 1.0)) * int(round(int(spawn.get("count", 0)) * count_mult))
        if "boss" in wave:
            total += float(bosses[wave["boss"]].get("hp_coef", 18.0))
        for spawn in wave.get("support", []):
            total += float(zombies[spawn["type"]].get("hp_coef", 1.0)) * int(round(int(spawn.get("count", 0)) * count_mult))
    return max(total, 1.0)


def total_spawn_seconds(waves: list[dict], economy: dict) -> float:
    duration = 0.0
    for wave in waves:
        count_mult = late_wave_count_mult(economy, wave_number(wave))
        for spawn in wave.get("spawns", []) + wave.get("support", []):
            duration += int(round(int(spawn.get("count", 0)) * count_mult)) * float(spawn.get("interval", 0.8))
    return duration


def difficulty_coef(n: int, boss_level: bool, waves: list[dict], zombies: dict, bosses: dict, characters: dict, weapons: dict, economy: dict) -> float:
    target_hp = estimate_player_dps(characters, weapons, economy, n) * total_spawn_seconds(waves, economy) * target_pressure_ratio(n, boss_level)
    raw = target_hp / (float(base_hp_ref(n)) * enemy_hp_weight(waves, zombies, bosses, economy))
    return round(max(0.08, raw), 3)


def target_spawn_seconds(n: int, boss_level: bool) -> float:
    if n <= 5:
        base = 48 + n * 5
    elif n <= 20:
        base = 76 + (n - 6) * 1.3
    elif n <= 65:
        base = 92 + min(12, (n - 21) * 0.32)
    else:
        base = 102
    if boss_level:
        base += 18
    return min(138 if boss_level else 104, base)


def spawn_interval(n: int, wave: int, pressure: float = 1.0) -> float:
    base = 1.06 - min(0.62, (n - 1) * 0.0072)
    wave_push = [0.08, 0.0, -0.05, -0.12, -0.08][wave - 1]
    return round(max(0.34, (base + wave_push) / pressure), 2)


def max_tier(n: int) -> int:
    if n <= 5:
        return 2
    if n <= 14:
        return 2
    if n <= 34:
        return 3
    if n <= 48:
        return 4
    return 5


def pool_by_tag(zombies: dict, tag: str, tier_cap: int) -> list[str]:
    result = []
    for enemy_id, row in zombies.items():
        if int(row.get("tier", 1)) <= tier_cap and tag in row.get("threat_tags", []):
            result.append(enemy_id)
    return sorted(result)


def fallback_pool(zombies: dict, tier_cap: int) -> list[str]:
    return sorted(enemy_id for enemy_id, row in zombies.items() if int(row.get("tier", 1)) <= tier_cap)


def pick(pool: list[str], n: int, salt: int) -> str:
    if not pool:
        raise ValueError("empty enemy pool")
    return pool[(n + salt) % len(pool)]


def wave_theme(n: int) -> list[str]:
    pattern = n % 10
    if n <= 2:
        return ["anti_swarm", "breach"]
    if pattern in (1, 6):
        return ["breach", "fast"]
    if pattern in (2, 7):
        return ["support", "tank"]
    if pattern in (3, 8):
        return ["fast", "burst"]
    if pattern in (4, 9):
        return ["tank", "elite"]
    return ["boss", "elite", "burst"]


def enemy_for(zombies: dict, n: int, tag: str, salt: int) -> str:
    tier_cap = max_tier(n)
    pool = pool_by_tag(zombies, tag, tier_cap)
    if not pool and tag == "anti_swarm":
        pool = pool_by_tag(zombies, "breach", tier_cap)
    if not pool:
        pool = fallback_pool(zombies, tier_cap)
    return pick(pool, n, salt)


def boss_for(n: int) -> str:
    if n <= 10:
        return "boss_tank_titan"
    if n <= 20:
        return "boss_inferno_maw"
    if n <= 30:
        return "boss_frost_warden"
    if n <= 40:
        return "boss_storm_caller"
    if n <= 50:
        return "boss_plague_mother"
    if n <= 65:
        return "boss_void_phantom"
    if n <= 80:
        return "boss_necrotitan"
    return "boss_apex_overlord"


def count_for(duration_budget: float, interval: float, groups: int, n: int, heavy: bool = False) -> int:
    raw = duration_budget / max(interval * max(groups, 1), 0.1)
    if heavy:
        raw *= 0.62
    limit = 34 if n <= 20 else 42 if n <= 55 else 52
    return max(3, min(limit, int(round(raw))))


def group(enemy_type: str, count: int, interval: float, lane: str) -> dict:
    return {"type": enemy_type, "count": int(count), "interval": float(interval), "lane": lane}


# Wave archetypes shape waves 1-4 (the boss/finale wave is handled separately).
# Each wave is a list of (enemy_role, lane) slots; the budget is split across slots.
WAVE_ARCHETYPES = {
    "standard": [
        [("filler", "spread")],
        [("fast", "right")],
        [("tank", "left")],
        [("fast", "left"), ("burst", "right")],
    ],
    "rush": [
        [("fast", "spread")],
        [("filler", "spread")],
        [("fast", "center")],
        [("fast", "left"), ("filler", "right")],
    ],
    "pincer": [
        [("filler", "left"), ("fast", "right")],
        [("fast", "left"), ("filler", "right")],
        [("tank", "left"), ("burst", "right")],
        [("burst", "left"), ("fast", "right")],
    ],
    "escort": [
        [("filler", "spread")],
        [("tank", "center")],
        [("elite", "center"), ("support", "spread")],
        [("tank", "left"), ("support", "right")],
    ],
    "siege": [
        [("filler", "spread")],
        [("burst", "left"), ("fast", "right")],
        [("tank", "spread")],
        [("elite", "left"), ("burst", "right")],
    ],
}

ARCHETYPE_CYCLE = ["standard", "rush", "pincer", "escort", "siege"]


def wave_archetype(n: int) -> str:
    # Early levels keep simple shapes for onboarding; later levels rotate through
    # all archetypes (offset by chapter) so no run replays the previous layout.
    if n <= 5:
        return "standard"
    if n <= 10:
        return ["rush", "pincer", "standard", "rush", "pincer"][(n - 6) % 5]
    return ARCHETYPE_CYCLE[(n + n // 5) % 5]


def is_boss_level(n: int) -> bool:
    # Every 5th level is a boss, and the campaign finale (99) always ends on a boss.
    return n % 5 == 0 or n == 99


def level_variant(n: int, boss_level: bool) -> str:
    # Variant levels break up the campaign rhythm. They are reward/flavour tags
    # only (consumed at runtime) and never alter the generated wave data, so the
    # monotonic pressure curve is preserved.
    if n == 99:
        return "boss_rush"
    if boss_level:
        return "boss"
    if n > 5:
        if n % 7 == 3:
            return "treasure"
        if n % 7 == 5:
            return "elite"
    return "normal"


def build_waves(n: int, zombies: dict, bosses: dict) -> tuple[list[dict], list[str], str, int]:
    boss_level = is_boss_level(n)
    tags = wave_theme(n)
    duration = target_spawn_seconds(n, boss_level)
    budgets = [0.16, 0.18, 0.20, 0.23, 0.23]
    waves: list[dict] = []
    xp_total = 0

    def add_xp(enemy_id: str, count: int) -> None:
        nonlocal xp_total
        xp_total += int(zombies[enemy_id].get("run_xp", 1)) * count

    filler = enemy_for(zombies, n, "breach", 1)
    fast = enemy_for(zombies, n, "fast", 2)
    tank = enemy_for(zombies, n, "tank", 3)
    burst = enemy_for(zombies, n, "burst", 4)
    support = enemy_for(zombies, n, "support", 5)
    elite = enemy_for(zombies, n, "elite", 6)

    pressure_factors = [0.95, 1.08, 1.0, 1.18]
    role_map = {
        "filler": filler,
        "fast": fast,
        "tank": tank,
        "burst": burst,
        "support": support,
        "elite": elite,
    }
    archetype = wave_archetype(n)
    for wave_index in range(4):
        wave_no = wave_index + 1
        slots = WAVE_ARCHETYPES[archetype][wave_index]
        interval = spawn_interval(n, wave_no, pressure_factors[wave_index])
        share = 1.0 / len(slots)
        spawns = []
        for role, lane in slots:
            enemy = role_map[role]
            heavy = role in ("tank", "elite")
            count = count_for(duration * budgets[wave_index] * share, interval, 1, n, heavy)
            add_xp(enemy, count)
            spawns.append(group(enemy, count, interval, lane))
        waves.append({"wave": wave_no, "spawns": spawns})

    if boss_level:
        boss_id = boss_for(n)
        boss_row = bosses[boss_id]
        support_interval = spawn_interval(n, 5, 1.06)
        support_a = support if int(zombies[support].get("tier", 1)) <= max_tier(n) else filler
        support_b = fast if n >= 10 else filler
        c5a = count_for(duration * budgets[4] * 0.42, support_interval, 1, n, support_a in (tank, elite))
        c5b = count_for(duration * budgets[4] * 0.30, support_interval, 1, n)
        add_xp(support_a, c5a)
        add_xp(support_b, c5b)
        xp_total += int(boss_row.get("run_xp", 25))
        waves.append({"wave": 5, "boss": boss_id, "support": [
            group(support_a, c5a, support_interval, "left"),
            group(support_b, c5b, support_interval, "right"),
        ]})
        tags = sorted(set(tags + ["boss", "elite"]))
        primary = str(boss_row.get("weakness", "physical"))
    else:
        i5 = spawn_interval(n, 5, 1.12)
        finale = elite if n >= 18 else tank if "tank" in tags else burst if "burst" in tags else fast
        c5 = count_for(duration * budgets[4], i5, 1, n, finale in (tank, elite))
        add_xp(finale, c5)
        waves.append({"wave": 5, "spawns": [group(finale, c5, i5, "spread")]})
        primary = str(zombies[finale].get("weakness", "physical"))

    return waves, sorted(set(tags)), primary, xp_total


def card_budget_fields(n: int, xp_total: int) -> dict:
    target_cards = target_card_picks(n)
    first = max(12, int(round(xp_total * (0.20 if n <= 5 else 0.16))))
    ramp = max(4, int(round(xp_total * 0.018)))
    if target_cards <= 1:
        growth = max(18, int(round(xp_total * 0.45)))
    else:
        ramp_sum = sum(range(1, target_cards)) * ramp
        growth = max(14, int(round((xp_total - first - ramp_sum) / max(target_cards - 1, 1))))
    return {
        "xp_first_offer": first,
        "xp_offer_growth": growth,
        "xp_offer_ramp": ramp,
        "target_card_picks": target_cards,
    }


def card_bias(tags: list[str], primary: str) -> dict:
    bias: dict[str, float] = {}
    for tag in tags:
        for key, value in BIAS_BY_TAG.get(tag, {}).items():
            bias[key] = max(float(bias.get(key, 1.0)), value)
    if primary in ("fire", "ice", "lightning", "poison", "physical"):
        bias[primary] = max(float(bias.get(primary, 1.0)), 1.35)
    return {key: round(value, 2) for key, value in sorted(bias.items())}


def first_clear_gold(n: int) -> int:
    return int(round(95 + 24 * n + 0.055 * n * n))


def reward_gold_mult(n: int) -> float:
    return round(max(0.18, 0.56 - 0.0036 * n), 2)


def level_pressure(level: dict, zombies: dict, bosses: dict, economy: dict) -> float:
    # Mirrors tools/check_level_pressure.py so the monotonic pass optimizes the
    # exact metric the validator enforces (uses hp_coef * bd_coef, boss hp * 8).
    raw = 0.0
    try:
        level_no = int(str(level.get("id", "level_000")).split("_")[-1])
    except (TypeError, ValueError):
        level_no = 0
    boss_level_bonus = boss_hp_level_bonus(economy, level_no)
    card_picks = int(level.get("target_card_picks", 4))
    for wave in level.get("waves", []):
        wave_no = wave_number(wave)
        mob_bonus = late_wave_hp_bonus(economy, wave_no, level_no=level_no, card_picks=card_picks)
        count_mult = late_wave_count_mult(economy, wave_no)
        for grp in wave.get("spawns", []) + wave.get("support", []):
            row = zombies[grp["type"]]
            count = int(round(int(grp.get("count", 1)) * count_mult))
            raw += count * float(row.get("hp_coef", 1.0)) * mob_bonus * float(row.get("bd_coef", 1.0))
        if "boss" in wave:
            raw += float(bosses[wave["boss"]].get("hp_coef", 1.0)) * late_wave_hp_bonus(economy, wave_no, True, level_no, card_picks) * boss_level_bonus * 8.0
    return raw * float(level.get("difficulty_coef", 1.0))


def enforce_monotonic_pressure(levels: list[dict], zombies: dict, bosses: dict, economy: dict) -> None:
    # Boss levels are intentional periodic spikes, so we make the two streams
    # (boss / non-boss) each monotonic non-decreasing instead of the raw series.
    # difficulty_coef is only ever scaled UP, so the game never gets easier.
    for boss_stream, min_growth in ((False, 1.02), (True, 1.05)):
        prev: float | None = None
        for level in levels:
            level_is_boss = any("boss" in wave for wave in level.get("waves", []))
            if level_is_boss != boss_stream:
                continue
            pressure = level_pressure(level, zombies, bosses, economy)
            if prev is not None and pressure < prev * min_growth:
                target = prev * min_growth
                scale = target / max(pressure, 1e-6)
                level["difficulty_coef"] = round(float(level["difficulty_coef"]) * scale, 3)
                pressure = level_pressure(level, zombies, bosses, economy)
            prev = pressure


def build_levels() -> list[dict]:
    zombies = load_json("zombies")
    bosses = load_json("bosses")
    characters = load_json("characters")
    weapons = load_json("weapons")
    economy = load_json("economy")
    levels: list[dict] = []
    names = [prefix + suffix for prefix in NAME_PREFIXES for suffix in NAME_SUFFIXES]
    for n in range(1, 100):
        boss_level = is_boss_level(n)
        level_id = f"level_{n:03d}"
        waves, tags, primary, xp_total = build_waves(n, zombies, bosses)
        level = {
            "id": level_id,
            "name": names[n - 1],
            "env": ENV_BY_DECADE[min((n - 1) // 10, len(ENV_BY_DECADE) - 1)],
            "chapter": (n - 1) // 10 + 1,
            "recommend_level": recommend_level(n),
            "difficulty_coef": difficulty_coef(n, boss_level, waves, zombies, bosses, characters, weapons, economy),
            "primary_weakness": primary,
            "base_hp_ref": base_hp_ref(n),
            "threat_tags": tags,
            "wave_pattern": wave_archetype(n),
            "variant": level_variant(n, boss_level),
            "card_bias": card_bias(tags, primary),
            **card_budget_fields(n, xp_total),
            "onboarding_stage": INTRO_STAGES.get(n, ""),
            "next_level": f"level_{n + 1:03d}" if n < 99 else "",
            "waves": waves,
            "star_rule": "base_hp_percent",
            "first_clear_reward": {"gold": first_clear_gold(n)},
            "reward_gold_mult": reward_gold_mult(n),
        }
        levels.append(level)
    enforce_monotonic_pressure(levels, zombies, bosses, economy)
    return levels


def main() -> int:
    levels = build_levels()
    dump_json(LEVELS_PATH, levels)
    print(f"Rebuilt {len(levels)} levels with timed pressure waves.")
    for index in [0, 4, 9, 19, 49, 98]:
        level = levels[index]
        print(
            f"{level['id']} {level['name']} coef={level['difficulty_coef']} "
            f"cards={level['target_card_picks']} weakness={level['primary_weakness']} tags={','.join(level['threat_tags'])}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
