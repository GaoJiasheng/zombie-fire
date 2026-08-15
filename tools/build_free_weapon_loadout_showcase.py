#!/usr/bin/env python3
"""Build phone-scale loadout showcase art for the eight free weapons.

The accepted image-generation masters live under source_refs and remain out of
the iOS export.  This builder performs only deterministic alpha-crop, resize and
centering work.  It never touches the combat handheld/turret assets or balance.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/production/source_refs/generated/free_weapon_loadout_showcase_2026_08_15"
OUTPUT = ROOT / "assets/production/sprites/weapons/loadout"
MANIFEST = SOURCE / "free_weapon_loadout_runtime_manifest_v1.json"
CONTACT = SOURCE / "free_weapon_loadout_runtime_contact_sheet_v1.png"
CANVAS = (720, 420)

WEAPONS = (
    "weapon_autocannon",
    "weapon_flamethrower",
    "weapon_cryocannon",
    "weapon_teslacoil",
    "weapon_venomlauncher",
    "weapon_railgun",
    "weapon_scattergun",
    "weapon_plasmacannon",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fit_alpha(master: Image.Image) -> Image.Image:
    image = master.convert("RGBA")
    alpha = image.getchannel("A")
    if alpha.getextrema()[0] == 255:
        raise RuntimeError("master has no transparent background")
    box = alpha.getbbox()
    if box is None:
        raise RuntimeError("master has an empty alpha silhouette")
    image = image.crop(box)
    target_w = round(CANVAS[0] * 0.90)
    target_h = round(CANVAS[1] * 0.84)
    scale = min(target_w / image.width, target_h / image.height)
    image = image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", CANVAS)
    canvas.alpha_composite(
        image,
        ((CANVAS[0] - image.width) // 2, (CANVAS[1] - image.height) // 2),
    )
    return canvas


def build() -> list[dict]:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    records: list[dict] = []
    runtime_images: list[Image.Image] = []
    for weapon_id in WEAPONS:
        source = SOURCE / f"{weapon_id}_raw.png"
        if not source.is_file():
            raise FileNotFoundError(source)
        with Image.open(source) as master:
            if master.mode != "RGBA":
                raise RuntimeError(f"{source.name} must be RGBA, got {master.mode}")
            runtime = fit_alpha(master)
        output = OUTPUT / f"{weapon_id}_loadout.png"
        runtime.save(output, optimize=True)
        runtime_images.append(runtime)
        records.append(
            {
                "weapon_id": weapon_id,
                "source": str(source.relative_to(ROOT)),
                "source_size": list(Image.open(source).size),
                "source_sha256": sha256(source),
                "runtime": str(output.relative_to(ROOT)),
                "runtime_size": list(runtime.size),
                "runtime_sha256": sha256(output),
                "runtime_alpha_bbox": list(runtime.getchannel("A").getbbox() or ()),
            }
        )

    contact = Image.new("RGB", (CANVAS[0] * 2, CANVAS[1] * 4), (6, 20, 24))
    draw = ImageDraw.Draw(contact)
    for index, (weapon_id, runtime) in enumerate(zip(WEAPONS, runtime_images)):
        x = (index % 2) * CANVAS[0]
        y = (index // 2) * CANVAS[1]
        contact.paste(runtime, (x, y), runtime)
        draw.rectangle((x + 4, y + 4, x + CANVAS[0] - 5, y + CANVAS[1] - 5), outline=(40, 118, 124), width=2)
        draw.text((x + 18, y + 14), weapon_id.removeprefix("weapon_"), fill=(241, 206, 127))
    contact.save(CONTACT, optimize=True)

    payload = {
        "task": "Free weapon loadout showcase rerender",
        "created_at": "2026-08-15T08:45:00+08:00",
        "canvas": list(CANVAS),
        "scope": "loadout display only; combat assets and gameplay values unchanged",
        "records": records,
        "contact_sheet": str(CONTACT.relative_to(ROOT)),
        "contact_sheet_sha256": sha256(CONTACT),
    }
    MANIFEST.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return records


if __name__ == "__main__":
    built = build()
    print(f"Built {len(built)} free-weapon loadout renders at {CANVAS[0]}x{CANVAS[1]}.")
