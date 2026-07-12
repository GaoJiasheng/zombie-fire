#!/usr/bin/env python3
from __future__ import annotations

import json
import random
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets/production/sprites/ui"
REF_DIR = ROOT / "assets/production/source_refs/generated/wave_progress_native_2026_07_11"
CONTACT_DIR = ROOT / "assets/production/contact_sheets"

TRACK_PATH = OUT_DIR / "ui_wave_progress.png"
FILL_PATH = OUT_DIR / "ui_wave_progress_fill_native.png"
CONTACT_PATH = CONTACT_DIR / "wave_progress_native_2026_07_11.png"
MANIFEST_PATH = REF_DIR / "wave_progress_native_manifest.json"


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def gradient(size: tuple[int, int], left: tuple[int, int, int], right: tuple[int, int, int], vertical_boost: float = 0.0) -> Image.Image:
    img = Image.new("RGBA", size)
    pix = img.load()
    w, h = size
    for y in range(h):
        v = y / max(h - 1, 1)
        sheen = 1.0 + vertical_boost * (0.5 - abs(v - 0.34)) * 2.0
        for x in range(w):
            t = x / max(w - 1, 1)
            r = int((left[0] * (1.0 - t) + right[0] * t) * sheen)
            g = int((left[1] * (1.0 - t) + right[1] * t) * sheen)
            b = int((left[2] * (1.0 - t) + right[2] * t) * sheen)
            pix[x, y] = (min(r, 255), min(g, 255), min(b, 255), 255)
    return img


def paste_masked(base: Image.Image, layer: Image.Image, mask: Image.Image, xy: tuple[int, int] = (0, 0)) -> None:
    if xy != (0, 0):
        full = Image.new("RGBA", base.size, (0, 0, 0, 0))
        full.alpha_composite(layer, xy)
        full_mask = Image.new("L", base.size, 0)
        full_mask.paste(mask, xy)
        base.alpha_composite(Image.composite(full, Image.new("RGBA", base.size, (0, 0, 0, 0)), full_mask))
    else:
        base.alpha_composite(Image.composite(layer, Image.new("RGBA", layer.size, (0, 0, 0, 0)), mask))


def add_noise(img: Image.Image, mask: Image.Image, amount: int, seed: int) -> None:
    rng = random.Random(seed)
    pix = img.load()
    mp = mask.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            if mp[x, y] == 0:
                continue
            delta = rng.randint(-amount, amount)
            r, g, b, a = pix[x, y]
            pix[x, y] = (
                max(0, min(255, r + delta)),
                max(0, min(255, g + delta)),
                max(0, min(255, b + delta)),
                a,
            )


def render_track() -> Image.Image:
    s = 4
    w, h = 720 * s, 46 * s
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    outer = (6 * s, 4 * s, w - 7 * s, h - 5 * s)
    outer_mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(outer_mask)
    md.rounded_rectangle(outer, radius=22 * s, fill=255)

    shadow = outer_mask.filter(ImageFilter.GaussianBlur(5 * s))
    shadow_layer = Image.new("RGBA", (w, h), (0, 0, 0, 120))
    paste_masked(img, shadow_layer, shadow)

    plate = gradient((w, h), (44, 29, 18), (16, 48, 55), 0.26)
    paste_masked(img, plate, outer_mask)
    add_noise(img, outer_mask, 4, 711)

    # Armored bevels and glass lip. These are raster highlights baked at native display size.
    for i, alpha in enumerate([210, 136, 74]):
        inset = (6 + i * 3) * s
        rect = (inset, (4 + i * 2) * s, w - inset - s, h - (5 + i * 2) * s)
        color = (236, 154, 56, alpha) if i == 0 else (116, 226, 240, alpha)
        draw.rounded_rectangle(rect, radius=max(8 * s, 22 * s - i * 4 * s), outline=color, width=max(1, (2 - i) * s))

    # End-cap armor blocks, rendered into the same native bitmap rather than stretched.
    cap_color_l = (96, 56, 27, 168)
    cap_color_r = (34, 92, 104, 156)
    for side in [0, 1]:
        x0 = 12 * s if side == 0 else w - 112 * s
        x1 = 112 * s if side == 0 else w - 12 * s
        color = cap_color_l if side == 0 else cap_color_r
        draw.rounded_rectangle((x0, 8 * s, x1, h - 9 * s), radius=15 * s, fill=color, outline=(10, 15, 18, 180), width=2 * s)
        notch_x = x1 - 25 * s if side == 0 else x0 + 25 * s
        draw.line((notch_x, 9 * s, notch_x + (-18 if side == 0 else 18) * s, 16 * s), fill=(238, 172, 70, 125), width=s)
        draw.line((notch_x, h - 10 * s, notch_x + (-18 if side == 0 else 18) * s, h - 17 * s), fill=(95, 226, 240, 110), width=s)

    channel = (38 * s, 13 * s, w - 39 * s, 32 * s)
    channel_mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(channel_mask).rounded_rectangle(channel, radius=10 * s, fill=232)
    channel_layer = gradient((w, h), (16, 12, 8), (5, 31, 40), 0.5)
    paste_masked(img, channel_layer, channel_mask)
    ImageDraw.Draw(img).rounded_rectangle(channel, radius=10 * s, outline=(255, 188, 64, 112), width=s)
    ImageDraw.Draw(img).rounded_rectangle((42 * s, 16 * s, w - 43 * s, 29 * s), radius=7 * s, outline=(98, 224, 240, 82), width=s)

    glare = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glare)
    gd.rounded_rectangle((72 * s, 15 * s, w - 92 * s, 19 * s), radius=2 * s, fill=(255, 230, 142, 34))
    gd.rounded_rectangle((132 * s, 19 * s, w - 164 * s, 21 * s), radius=s, fill=(92, 240, 255, 22))
    paste_masked(img, glare, outer_mask)

    # Tiny surface wear: sparse scratches, not vector outlines.
    rng = random.Random(1311)
    for _ in range(34):
        x = rng.randint(52 * s, w - 60 * s)
        y = rng.randint(8 * s, h - 10 * s)
        length = rng.randint(8 * s, 26 * s)
        alpha = rng.randint(18, 42)
        draw.line((x, y, x + length, y + rng.randint(-2 * s, 2 * s)), fill=(255, 238, 190, alpha), width=1)

    return img.resize((720, 46), Image.Resampling.LANCZOS)


def render_fill() -> Image.Image:
    s = 4
    w, h = 640 * s, 18 * s
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    mask = rounded_mask((w, h), 7 * s)
    fill = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fp = fill.load()
    for y in range(h):
        v = y / max(h - 1, 1)
        center = max(0.0, 1.0 - abs(v - 0.46) * 2.2)
        edge = max(0.0, abs(v - 0.50) * 2.0 - 0.45)
        for x in range(w):
            t = x / max(w - 1, 1)
            warm = 0.74 + 0.20 * center - 0.10 * edge
            r = int((218 * (1.0 - t) + 255 * t) * warm)
            g = int((142 * (1.0 - t) + 216 * t) * warm)
            b = int((20 * (1.0 - t) + 62 * t) * warm)
            fp[x, y] = (min(r, 255), min(g, 255), min(b, 255), 255)
    paste_masked(img, fill, mask)
    add_noise(img, mask, 2, 907)

    # Very broad bloom only. Avoid crisp interior stripes/segment lines; the fill is clipped
    # at runtime, so any hard horizontal detail becomes visually noisy at partial progress.
    bloom = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bloom)
    bd.rounded_rectangle((22 * s, 3 * s, w - 23 * s, h - 4 * s), radius=7 * s, fill=(255, 226, 82, 26))
    bloom = bloom.filter(ImageFilter.GaussianBlur(5 * s))
    paste_masked(img, bloom, mask)
    return img.resize((640, 18), Image.Resampling.LANCZOS)


def make_contact(track: Image.Image, fill: Image.Image) -> Image.Image:
    sheet = Image.new("RGBA", (780, 180), (8, 13, 18, 255))
    sheet.alpha_composite(track, (30, 32))
    sheet.alpha_composite(fill, (70, 100))
    draw = ImageDraw.Draw(sheet)
    draw.text((30, 10), "Native wave progress: 720x46 track + 640x18 fill", fill=(220, 229, 226, 255))
    draw.text((70, 122), "Fill is clipped at runtime; never horizontally scaled as progress changes.", fill=(152, 176, 177, 255))
    return sheet


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    REF_DIR.mkdir(parents=True, exist_ok=True)
    CONTACT_DIR.mkdir(parents=True, exist_ok=True)

    track = render_track()
    fill = render_fill()
    track.save(TRACK_PATH)
    fill.save(FILL_PATH)
    make_contact(track, fill).save(CONTACT_PATH)

    manifest = {
        "task": "native wave progress HUD rerender",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "outputs": [
            str(TRACK_PATH.relative_to(ROOT)),
            str(FILL_PATH.relative_to(ROOT)),
            str(CONTACT_PATH.relative_to(ROOT)),
        ],
        "display_size": {"track": [720, 46], "fill": [640, 18]},
        "runtime_contract": "Track is rendered at exact HUD size. Fill texture remains full-width inside FillClip; progress changes only clip width, never stretch/compress texture.",
        "style": "armored glass sci-fi HUD, warm yellow progress, cyan/orange bevels, raster PNG only",
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {TRACK_PATH}")
    print(f"wrote {FILL_PATH}")
    print(f"wrote {CONTACT_PATH}")
    print(f"wrote {MANIFEST_PATH}")


if __name__ == "__main__":
    main()
