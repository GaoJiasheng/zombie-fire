#!/usr/bin/env python3
from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
LEVELS_PATH = DATA / "levels.json"

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


def load_json(name: str):
    return json.loads((DATA / f"{name}.json").read_text(encoding="utf-8"))


def dump_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")


def base_hp_ref(n: int) -> int:
    return int(round(110 + n * 6.5 + math.sqrt(n) * 7))


def target_effective_hp_base(n: int, boss_level: bool) -> float:
    if n <= 5:
        base = 70.0 + 15.0 * float(n - 1)
    elif n <= 10:
        base = 130.0 + 20.0 * float(n - 5)
    else:
        base = 230.0 + 56.0 * float(n - 10)
    if boss_level:
        base *= 1.08
    return base


def difficulty_coef(n: int, boss_level: bool) -> float:
    return round(target_effective_hp_base(n, boss_level) / float(base_hp_ref(n)), 3)


def recommend_level(n: int) -> int:
    return min(50, max(1, int(round(1 + (n - 1) * 0.78))))


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


def build_waves(n: int, zombies: dict, bosses: dict) -> tuple[list[dict], list[str], str, int]:
    boss_level = n % 5 == 0
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

    i1 = spawn_interval(n, 1, 0.95)
    c1 = count_for(duration * budgets[0], i1, 1, n)
    add_xp(filler, c1)
    waves.append({"wave": 1, "spawns": [group(filler, c1, i1, "spread")]})

    i2 = spawn_interval(n, 2, 1.08)
    second = fast if "fast" in tags or n >= 6 else filler
    c2 = count_for(duration * budgets[1], i2, 1, n)
    add_xp(second, c2)
    waves.append({"wave": 2, "spawns": [group(second, c2, i2, LANES[(n + 1) % 4])]})

    i3 = spawn_interval(n, 3, 1.0)
    third = tank if "tank" in tags else burst if "burst" in tags else support if "support" in tags else fast
    if boss_level and n >= 35:
        third = elite
    heavy_third = third in (tank, elite)
    c3 = count_for(duration * budgets[2], i3, 1, n, heavy_third)
    add_xp(third, c3)
    waves.append({"wave": 3, "spawns": [group(third, c3, i3, LANES[(n + 2) % 4])]})

    i4 = spawn_interval(n, 4, 1.18)
    pressure_a = fast if "fast" in tags else filler
    pressure_b = burst if "burst" in tags else support if "support" in tags else tank
    if boss_level and n >= 35:
        pressure_b = tank
    c4a = count_for(duration * budgets[3] * 0.56, i4, 1, n, pressure_a in (tank, elite))
    c4b = count_for(duration * budgets[3] * 0.44, i4, 1, n, pressure_b in (tank, elite))
    add_xp(pressure_a, c4a)
    add_xp(pressure_b, c4b)
    waves.append({"wave": 4, "spawns": [
        group(pressure_a, c4a, i4, "left"),
        group(pressure_b, c4b, i4, "right"),
    ]})

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
    if n <= 5:
        target_cards = 2
    elif n <= 10:
        target_cards = 3
    elif n <= 30:
        target_cards = 5
    elif n <= 65:
        target_cards = 6
    else:
        target_cards = 7
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


def build_levels() -> list[dict]:
    zombies = load_json("zombies")
    bosses = load_json("bosses")
    levels: list[dict] = []
    names = [prefix + suffix for prefix in NAME_PREFIXES for suffix in NAME_SUFFIXES]
    for n in range(1, 100):
        boss_level = n % 5 == 0
        level_id = f"level_{n:03d}"
        waves, tags, primary, xp_total = build_waves(n, zombies, bosses)
        level = {
            "id": level_id,
            "name": names[n - 1],
            "env": "env_city_ruins",
            "chapter": (n - 1) // 10 + 1,
            "recommend_level": recommend_level(n),
            "difficulty_coef": difficulty_coef(n, boss_level),
            "primary_weakness": primary,
            "base_hp_ref": base_hp_ref(n),
            "threat_tags": tags,
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
