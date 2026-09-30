"""Codex coverage and existing asset references; no combat-data mutation."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
codex = json.loads((root / "data/enemy_codex.json").read_text())
rows = {}
for table in ("zombies", "bosses"):
    rows.update(json.loads((root / f"data/{table}.json").read_text()))
assert set(codex["entries"]) == set(rows), "Codex must cover exactly the shipped enemy roster"
for field in ("guide_zh", "guide_en", "story_zh", "story_en"):
    values = [entry[field] for entry in codex["entries"].values()]
    assert all(len(value) >= 30 for value in values), f"Incomplete {field}"
    assert len(set(values)) == len(values), f"Generic duplicate {field}"
for label in codex["labels"].values():
    assert label.get("text_zh") and label.get("text_en"), "Missing bilingual label"
for language in ("zh", "en"):
    siege = [entry["siege_" + language] for key, entry in codex["entries"].items() if key.startswith("boss_")]
    assert len(siege) == 8 and len(set(siege)) == 8 and all(len(s) > 40 for s in siege), "Each boss needs distinct siege guidance"
for enemy_id, row in rows.items():
    path = root / row["sprite"].removeprefix("res://")
    assert path.is_file(), f"Missing asset for {enemy_id}: {path}"
print(f"Bestiary OK: {len(rows)} unique bilingual dossiers, stories and existing portraits")
