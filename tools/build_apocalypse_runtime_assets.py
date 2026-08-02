#!/usr/bin/env python3
"""Build runtime-sized Thunder Apocalypse assets from transparent masters."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = (
    ROOT
    / "assets/production/source_refs/generated"
    / "premium_neon_tempest_phase1_commerce_2026_07_29"
)
OUTPUT = ROOT / "assets/production/sprites/premium/neon_tempest"

VARIANTS = {
    "weapon_apocalypse_thunder_master.png": (
        ("weapon_apocalypse_thunder_icon.png", (384, 384), False),
        ("weapon_apocalypse_thunder_handheld.png", (720, 420), True),
        ("weapon_apocalypse_thunder_turret.png", (520, 520), True),
    ),
    "armor_apocalypse_conductor_master.png": (
        ("armor_apocalypse_conductor_icon.png", (384, 384), False),
    ),
    "chip_apocalypse_superconductive_master.png": (
        ("chip_apocalypse_superconductive_icon.png", (384, 384), False),
    ),
    "pet_apocalypse_tempest_master.png": (
        ("pet_apocalypse_tempest_icon.png", (384, 384), False),
        ("pet_apocalypse_tempest_prototype.png", (320, 320), False),
    ),
}


def main() -> None:
    for master_name, variants in VARIANTS.items():
        image = Image.open(SOURCE / master_name).convert("RGBA")
        image = image.crop(image.getbbox())
        for name, size, flip in variants:
            source = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if flip else image
            scale = min(size[0] * 0.90 / source.width, size[1] * 0.90 / source.height)
            resized = source.resize(
                (round(source.width * scale), round(source.height * scale)),
                Image.Resampling.LANCZOS,
            )
            canvas = Image.new("RGBA", size)
            canvas.alpha_composite(
                resized, ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2)
            )
            canvas.save(OUTPUT / name, optimize=True)
    print("Thunder Apocalypse runtime assets rebuilt")


if __name__ == "__main__":
    main()
