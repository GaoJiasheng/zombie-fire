#!/usr/bin/env python3
from __future__ import annotations

import json
import random
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(name: str):
    return json.loads((ROOT / "data" / f"{name}.json").read_text(encoding="utf-8"))


def build_bias(level: dict, character: dict, weapon: dict) -> dict:
    bias = dict(level.get("card_bias", {}))
    for tag in level.get("threat_tags", []):
        if tag == "fast":
            bias["control"] = bias.get("control", 1.0) + 0.9
            bias["ice"] = bias.get("ice", 1.0) + 0.6
        elif tag == "tank":
            bias["pierce"] = bias.get("pierce", 1.0) + 0.8
            bias["execute"] = bias.get("execute", 1.0) + 0.6
        elif tag == "support":
            bias["homing"] = bias.get("homing", 1.0) + 0.7
            bias["chain"] = bias.get("chain", 1.0) + 0.6
        elif tag == "burst":
            bias["defense"] = bias.get("defense", 1.0) + 0.8
        elif tag == "breach":
            bias["anti_swarm"] = bias.get("anti_swarm", 1.0) + 0.7
    for tag in character.get("card_affinity_tags", []):
        bias[tag] = bias.get(tag, 1.0) + 1.1
    element = weapon.get("element", "physical")
    if element:
        bias[element] = bias.get(element, 1.0) + 1.2
    return bias


def matches_loadout(row: dict, character: dict, weapon: dict) -> bool:
    tags = row.get("card_tags", [])
    if any(tag in tags for tag in character.get("card_affinity_tags", [])):
        return True
    return weapon.get("element", "") in tags


def offer(skills: dict, level: dict, owned: dict[str, int], character: dict, weapon: dict, count: int = 3) -> list[str]:
    bias = build_bias(level, character, weapon)
    weighted: list[str] = []
    for skill_id, row in skills.items():
        weight = 4 + int(owned.get(skill_id, 0))
        for tag in row.get("card_tags", []):
            weight += round(float(bias.get(tag, 1.0)) * 2.0)
        if matches_loadout(row, character, weapon):
            weight += 4
        weighted.extend([skill_id] * max(weight, 1))
    result: list[str] = []
    while len(result) < count and weighted:
        picked = random.choice(weighted)
        if picked not in result:
            result.append(picked)
        weighted = [item for item in weighted if item != picked]
    return result


def main() -> int:
    random.seed(42)
    skills = load("skills")
    levels = load("levels")
    characters = load("characters")
    weapons = load("weapons")
    character = characters["vanguard"]
    weapon = weapons["weapon_autocannon"]
    print("Card offer simulation: 1000 runs per level")
    for level in levels:
        counts: Counter[str] = Counter()
        for _ in range(1000):
            for skill_id in offer(skills, level, {}, character, weapon):
                counts[skill_id] += 1
        top = ", ".join(f"{skill}:{count / 10:.1f}%" for skill, count in counts.most_common())
        print(f"{level['id']}: {top}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
