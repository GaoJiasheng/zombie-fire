#!/usr/bin/env python3
"""Build true-grip Thunder Apocalypse battle sprites from approved masters.

The approved source art deliberately bakes the Neon Tempest garment structure
into the hero/weapon silhouette. Moving rainbow flow, electricity, muzzle
light, recoil and projectile effects remain runtime layers.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = (
    ROOT
    / "assets/production/source_refs/generated"
    / "premium_neon_tempest_thunder_true_grip_2026_07_29"
)
OUTPUT = (
    ROOT
    / "assets/production/sprites/premium/neon_tempest/true_grip"
)
CONTACT_SHEET = SOURCE / "thunder_apocalypse_true_grip_runtime_contact_sheet.png"
BLAZE_RAISED_RIGHT = SOURCE / "char_blaze_neon_raised_right_alpha_v2.png"

HEROES = ("char_vanguard", "char_blaze", "char_frost", "char_volt")
CANVAS_SIZE = (380, 520)
CONTENT_SIZE = (360, 500)


def _clean_transparency(image: Image.Image) -> Image.Image:
    """Remove green RGB residue so downsampling cannot create a chroma halo."""
    image = image.convert("RGBA")
    cleaned = []
    for red, green, blue, alpha in image.getdata():
        if alpha <= 2:
            cleaned.append((0, 0, 0, 0))
            continue
        if green > max(red, blue) * 1.22 and green > 90:
            green = min(green, max(red, blue) + 10)
        cleaned.append((red, green, blue, alpha))
    image.putdata(cleaned)
    return image


def _fit_master(image: Image.Image) -> Image.Image:
    image = _clean_transparency(image)
    bounds = image.getbbox()
    if bounds is None:
        raise RuntimeError("Approved true-grip master is empty")
    image = image.crop(bounds)
    scale = min(CONTENT_SIZE[0] / image.width, CONTENT_SIZE[1] / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", CANVAS_SIZE)
    left = (CANVAS_SIZE[0] - resized.width) // 2
    top = (CANVAS_SIZE[1] - resized.height) // 2
    canvas.alpha_composite(resized, (left, top))
    return canvas


def _checkerboard(size: tuple[int, int], cell: int = 20) -> Image.Image:
    image = Image.new("RGBA", size, (18, 23, 32, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle(
                    (x, y, x + cell - 1, y + cell - 1),
                    fill=(28, 36, 48, 255),
                )
    return image


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    rendered: dict[tuple[str, str], Image.Image] = {}
    for hero in HEROES:
        # Blaze's original diagonal master held the cannon almost horizontally.
        # On the portrait battlefield that reads as aiming outside the useful
        # enemy corridor, so only its paired side poses use the reviewed raised
        # master.  The accepted centre master remains deliberately untouched.
        right_source = (
            BLAZE_RAISED_RIGHT
            if hero == "char_blaze"
            else SOURCE / f"{hero}_neon_alpha.png"
        )
        right = _fit_master(Image.open(right_source))
        center = _fit_master(
            Image.open(SOURCE / f"{hero}_neon_center_alpha.png")
        )
        left = right.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        for aim, image in (("left", left), ("center", center), ("right", right)):
            suffix = "attack" if aim == "center" else f"attack_{aim}"
            path = OUTPUT / f"{hero}_apocalypse_{suffix}.png"
            image.save(path, optimize=True)
            rendered[(hero, aim)] = image
            print(f"{path.relative_to(ROOT)} alpha={image.getbbox()}")

    cell_width, cell_height = CANVAS_SIZE
    label_height = 34
    sheet = _checkerboard(
        (cell_width * 3, (cell_height + label_height) * len(HEROES))
    )
    draw = ImageDraw.Draw(sheet)
    for row, hero in enumerate(HEROES):
        for column, aim in enumerate(("left", "center", "right")):
            x = column * cell_width
            y = row * (cell_height + label_height)
            sheet.alpha_composite(rendered[(hero, aim)], (x, y))
            draw.text(
                (x + 10, y + cell_height + 8),
                f"{hero} · {aim}",
                fill=(224, 242, 255, 255),
            )
    sheet.convert("RGB").save(CONTACT_SHEET, quality=94)
    print(f"{CONTACT_SHEET.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
