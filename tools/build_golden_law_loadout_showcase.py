#!/usr/bin/env python3
"""Build the reviewed Golden Law V3 loadout-only product render.

The accepted transparent generation master remains under source_refs. This
builder performs deterministic alpha crop, resize, centering, hashing and a
review contact sheet. Inventory icon, battle handheld/turret art and balance
are deliberately outside this task.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets/production/source_refs/generated/premium_black_gold_golden_law_phase4_2026_08_01"
SOURCE = SOURCE_DIR / "golden_law_weapon_loadout_v3_raw.png"
OUTPUT = ROOT / "assets/production/sprites/premium/gilded_eclipse/weapon_apocalypse_golden_law_loadout_v3.png"
MANIFEST = SOURCE_DIR / "golden_law_weapon_loadout_v3_manifest.json"
CONTACT = SOURCE_DIR / "golden_law_weapon_loadout_v3_contact_sheet.png"
CANVAS = (720, 420)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fit_alpha(master: Image.Image) -> Image.Image:
    image = master.convert("RGBA")
    alpha = image.getchannel("A")
    if alpha.getextrema()[0] == 255:
        raise RuntimeError("Golden Law V3 source must have genuine transparency")
    box = alpha.getbbox()
    if box is None:
        raise RuntimeError("Golden Law V3 source has an empty alpha silhouette")
    image = image.crop(box)
    scale = min(CANVAS[0] * 0.96 / image.width, CANVAS[1] * 0.90 / image.height)
    image = image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", CANVAS)
    canvas.alpha_composite(image, ((CANVAS[0] - image.width) // 2, (CANVAS[1] - image.height) // 2))
    return canvas


def build() -> None:
    if not SOURCE.is_file():
        raise FileNotFoundError(SOURCE)
    with Image.open(SOURCE) as master:
        if master.mode != "RGBA":
            raise RuntimeError(f"Golden Law V3 source must be RGBA, got {master.mode}")
        runtime = fit_alpha(master)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    runtime.save(OUTPUT, optimize=True)

    contact = Image.new("RGB", (900, 540), (5, 9, 13))
    draw = ImageDraw.Draw(contact)
    contact.paste(runtime, ((contact.width - runtime.width) // 2, 76), runtime)
    draw.rectangle((34, 40, 866, 500), outline=(185, 132, 43), width=3)
    draw.text((54, 52), "GOLDEN LAW V3 / LOADOUT PRODUCT RENDER", fill=(246, 211, 117))
    draw.text((54, 472), "blackened gunmetal / liquid-gold tribunal core / horizontal verdict cannon", fill=(194, 178, 141))
    contact.save(CONTACT, optimize=True)

    payload = {
        "task": "Golden Law dedicated explosive loadout rerender",
        "created_at": "2026-08-15T10:20:00+08:00",
        "scope": "loadout display only; inventory icon, combat art, VFX and gameplay values unchanged",
        "source": str(SOURCE.relative_to(ROOT)),
        "source_size": list(Image.open(SOURCE).size),
        "source_sha256": sha256(SOURCE),
        "runtime": str(OUTPUT.relative_to(ROOT)),
        "runtime_size": list(runtime.size),
        "runtime_alpha_bbox": list(runtime.getchannel("A").getbbox() or ()),
        "runtime_sha256": sha256(OUTPUT),
        "contact_sheet": str(CONTACT.relative_to(ROOT)),
        "contact_sheet_sha256": sha256(CONTACT),
    }
    MANIFEST.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Built Golden Law V3 loadout render at {CANVAS[0]}x{CANVAS[1]}.")


if __name__ == "__main__":
    build()
