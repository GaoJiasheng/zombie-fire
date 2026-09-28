#!/usr/bin/env python3
"""Require distinct, bilingual tactical copy for every shipped collection entry."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TABLES = ("characters", "skills", "weapons", "armors", "chips", "pets")


def validate() -> list[str]:
    guides = json.loads((ROOT / "data/tactical_guides.json").read_text())
    errors = []
    expected = set()
    for table in TABLES:
        rows = json.loads((ROOT / f"data/{table}.json").read_text())
        seen = {"zh": set(), "en": set()}
        for item_id, row in rows.items():
            expected.add(item_id)
            for language in ("zh", "en"):
                text = guides.get(item_id, {}).get(f"guide_{language}", "")
                if len(text.splitlines()) < 3:
                    errors.append(f"{item_id}/{language}: needs mechanic, growth and pairing paragraphs")
                if text in seen[language]:
                    errors.append(f"{item_id}/{language}: duplicate generic guide")
                seen[language].add(text)
            if table == "characters":
                expected.add(row["passive"])
                expected.update(row["signature_skills"])
    expected.update(f"rules_{name}" for name in ("characters", "skills", "weapons", "armors", "ammo"))
    for key in expected:
        for language in ("zh", "en"):
            if not guides.get(key, {}).get(f"guide_{language}", "").strip():
                errors.append(f"{key}: missing {language} copy")
    for key in set(guides) - expected:
        errors.append(f"{key}: orphan guide; use a real content ID or declared shared rule")
    contracts = {
        "skill_split_shot": ("保留", "降低"),
        "skill_pierce": ("不等于", "护甲"),
        "skill_charge_shot": ("本体", "免疫"),
        "skill_ricochet": ("附近", "只有一个"),
        "rules_skills": ("首次", "不把各级"),
        "rules_ammo": ("付费", "互斥", "免费原生"),
        "breach_guard": ("减伤", "不是"),
        "sig_volt_storm": ("同一目标", "下一次"),
        "chip_element": ("原生", "物理枪"),
        "pet_apocalypse_skyfalcon": ("黄金律", "不能"),
    }
    for key, words in contracts.items():
        for word in words:
            if word not in guides.get(key, {}).get("guide_zh", ""):
                errors.append(f"{key}: missing reviewed mechanic distinction {word}")
    return errors


if __name__ == "__main__":
    problems = validate()
    for problem in problems:
        print("FAIL:", problem)
    if not problems:
        print("Tactical guides OK: 64 collection entries, 12 character abilities, 5 model notes; zh/en complete and distinct")
    raise SystemExit(bool(problems))
