#!/usr/bin/env python3
"""Capture the FONT_SCALE 1.5 card-detail matrix without touching real saves."""

from __future__ import annotations

import json
import os
import shutil
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
OUTPUT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "tools"))

import check_visual_screens as visual  # noqa: E402


SIZES = (
    (1080, 1920, "1080x1920"),
    (1320, 2868, "1320x2868"),
    (750, 1334, "750x1334"),
)

# Split Shot owns the explicit release contract. Incendiary Ammo is the longest
# Chinese detail paragraph and therefore the complementary worst-case capture.
LOCALES = (
    ("zh", "skill_incendiary"),
    ("en", "skill_split_shot"),
)


def main() -> int:
    errors: list[str] = []
    manifest: list[dict] = []
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="zf_modal_evidence_") as capture_dir, tempfile.TemporaryDirectory(
        prefix="zf_modal_home_"
    ) as visual_home:
        os.environ["ZOMBIE_FIRE_VISUAL_HOME"] = visual_home
        capture_root = Path(capture_dir)
        for width, height, size_name in SIZES:
            for language, skill_id in LOCALES:
                label = f"card_detail_{size_name}_{language}_{skill_id}"
                temporary_path = capture_root / f"{label}.png"
                payload = {
                    "language": language,
                    "level_id": "level_001",
                    "card_detail": skill_id,
                    "viewport_size": [width, height],
                }
                code, audit_issues, output = visual.capture("battle", payload, temporary_path)
                image_issues = [] if code != 0 else visual.analyze(temporary_path, label, (width, height))
                if code != 0:
                    errors.append(f"{label}: capture exited {code}: {output[-800:]}")
                errors.extend(f"{label}: {issue}" for issue in audit_issues)
                errors.extend(f"{label}: {issue}" for issue in image_issues)
                if temporary_path.exists():
                    shutil.copy2(temporary_path, OUTPUT / temporary_path.name)
                manifest.append(
                    {
                        "label": label,
                        "language": language,
                        "skill_id": skill_id,
                        "viewport_size": [width, height],
                        "capture_code": code,
                        "runtime_audit_issues": audit_issues,
                        "image_analysis_issues": image_issues,
                    }
                )
    (OUTPUT / "capture_manifest.json").write_text(
        json.dumps(
            {
                "font_scale": 1.5,
                "screen_count": len(manifest),
                "error_count": len(errors),
                "screens": manifest,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    if errors:
        print("Battle modal evidence capture failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Battle modal evidence capture OK: {len(manifest)} screenshots")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
