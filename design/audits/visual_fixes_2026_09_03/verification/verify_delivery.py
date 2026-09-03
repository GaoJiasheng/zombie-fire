#!/usr/bin/env python3
"""Validate the round-three evidence, then copy only this package to Desktop."""
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess

from PIL import Image

ROOT = Path(__file__).resolve().parents[4]
AUDIT = Path(__file__).resolve().parents[1]
DESTINATION = Path("/Users/gavin/Desktop/zombiefire_screenshots/12_视觉第三轮")


def command(*args):
    return subprocess.check_output(args, cwd=ROOT, text=True).strip()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    rows = []
    for group, expected in (("x1", 6), ("x2", 16), ("x3", 26), ("x4", 6), ("modal_order", 4)):
        manifest = AUDIT / group / "after/manifest.json"
        entries = json.loads(manifest.read_text())
        assert len(entries) == expected, group
        for entry in entries:
            assert entry["capture_exit"] == 0 and entry["issues"] == [], entry["label"]
            path = manifest.parent / entry["png"]
            with Image.open(path) as image:
                assert image.size == tuple(entry["payload"]["viewport_size"]), path
            rows.append({"path": str(path.relative_to(AUDIT)), "sha256": sha(path)})
    rc = (AUDIT / "verification/final_rc.log").read_text()
    assert "Release candidate check OK" in rc and "M1 smoke test passed" in rc
    assert "check failed" not in rc.lower() and re.search(r"^(SCRIPT )?ERROR:", rc, re.M) is None
    fingerprint = command("python3", "tools/free_side_fingerprint.py", ".")
    assert fingerprint == command("python3", "tools/free_side_fingerprint.py", ".", "main")
    assert command("git", "diff", "648b040e", "--", "gameplay", "core", "data", "ui") == ""
    assert command("git", "diff", "--check") == ""
    shared_save_root = Path("/Users/gavin/Library/Application Support/Godot/app_userdata/Zombie Fire")
    assert all(not (shared_save_root / name).exists() for name in ("save_main.json", "save_backup.json"))
    report = {
        "verified_code_head": command("git", "rev-parse", "HEAD"),
        "baseline": "648b040e",
        "fingerprint_matches_local_main": fingerprint,
        "unchanged_domains": ["gameplay", "core", "data", "ui"],
        "after_captures": rows,
        "after_count": len(rows),
        "before_count": len(list(AUDIT.glob("*/before/*.png"))),
        "comparison_count": len(list(AUDIT.glob("*/comparisons/*.png"))),
        "aggregate_gate": "Release candidate check OK; M1 smoke test passed; no ERROR or check failed",
        "desktop": str(DESTINATION),
        "shared_test_saves_removed": ["save_main.json", "save_backup.json"],
    }
    assert report["before_count"] == 54 and report["comparison_count"] == 54
    # This destination is explicitly requested. No deletion or broad sync occurs.
    files = [path for path in AUDIT.rglob("*") if path.is_file() and path.name != "delivery_integrity.json"]
    for source in files:
        target = DESTINATION / source.relative_to(AUDIT)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        assert sha(source) == sha(target), target
    report["desktop_files_verified"] = len(files) + 1
    proof = AUDIT / "verification/delivery_integrity.json"
    proof.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    shutil.copy2(proof, DESTINATION / proof.relative_to(AUDIT))
    print(json.dumps({key: value for key, value in report.items() if key != "after_captures"}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
