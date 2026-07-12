#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "assets/production/sprites/vfx/vfx_barrier_glass.png"
SOURCE_DIR = ROOT / "assets/production/source_refs/generated/barrier_glass_redo_2026_07_09"
CONTACT_SHEET = ROOT / "assets/production/contact_sheets/barrier_glass_redo_2026_07_09.png"
IMAGEGEN_SOURCE = SOURCE_DIR / "imagegen_barrier_source.png"
WIDTH = 960
HEIGHT = 260
RNG = random.Random(20260709)


def _clamp(value: float, low: float = 0.0, high: float = 255.0) -> int:
    return int(max(low, min(high, value)))


def _edge_fade(x: int, y: int) -> float:
    margin_x = 34.0
    margin_y = 22.0
    return min(1.0, x / margin_x, (WIDTH - 1 - x) / margin_x, y / margin_y, (HEIGHT - 1 - y) / margin_y)


def _make_field() -> Image.Image:
    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    px = image.load()
    for y in range(HEIGHT):
        for x in range(WIDTH):
            nx = abs((x - WIDTH * 0.5) / (WIDTH * 0.5))
            top = 42.0 + 44.0 * (nx ** 1.65)
            bottom = 214.0 - 18.0 * (nx ** 1.4)
            if y < top or y > bottom:
                continue
            v = (y - top) / max(1.0, bottom - top)
            edge = min(v, 1.0 - v)
            side = max(0.0, 1.0 - nx)
            shimmer = (
                math.sin(x * 0.023 + y * 0.055) * 0.5
                + math.sin(x * 0.071 - y * 0.028) * 0.28
                + RNG.random() * 0.22
            )
            core = 0.22 + 0.48 * (edge ** 0.38) + 0.16 * side + 0.06 * shimmer
            alpha = _clamp(116.0 * core * _edge_fade(x, y), 0, 126)
            if alpha <= 0:
                continue
            r = _clamp(30 + 26 * side + shimmer * 14)
            g = _clamp(166 + 46 * side + shimmer * 22)
            b = _clamp(210 + 34 * side + shimmer * 18)
            px[x, y] = (r, g, b, alpha)
    return image.filter(ImageFilter.GaussianBlur(0.35))


def _soft_line(size: int, color: tuple[int, int, int, int], blur: float) -> Image.Image:
    line = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(line)
    return line, draw, color, blur


def _draw_curve(layer: Image.Image, points: list[tuple[float, float]], color: tuple[int, int, int, int], width: int, blur: float = 0.0) -> None:
    temp = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(temp)
    draw.line(points, fill=color, width=width, joint="curve")
    if blur > 0:
        temp = temp.filter(ImageFilter.GaussianBlur(blur))
    layer.alpha_composite(temp)


def _draw_energy_edges(base: Image.Image) -> None:
    glow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    for offset, alpha, width, blur in [
        (0.0, 96, 9, 7.0),
        (5.0, 74, 5, 3.4),
        (-6.0, 90, 4, 1.4),
    ]:
        top_points = []
        bottom_points = []
        for i in range(90):
            t = i / 89.0
            x = 38 + t * (WIDTH - 76)
            nx = abs((x - WIDTH * 0.5) / (WIDTH * 0.5))
            top_y = 42.0 + 44.0 * (nx ** 1.65) + math.sin(t * math.tau * 2.0) * 2.4 + offset
            bottom_y = 214.0 - 18.0 * (nx ** 1.4) + math.sin(t * math.tau * 1.55 + 0.8) * 2.2 - offset * 0.3
            top_points.append((x, top_y))
            bottom_points.append((x, bottom_y))
        _draw_curve(glow, top_points, (118, 238, 255, alpha), width, blur)
        _draw_curve(glow, bottom_points, (68, 225, 255, int(alpha * 0.8)), max(2, width - 2), blur)

    for _ in range(22):
        x0 = RNG.uniform(95, WIDTH - 95)
        y0 = RNG.uniform(70, 200)
        length = RNG.uniform(70, 180)
        angle = RNG.uniform(-0.55, 0.55)
        points = []
        for i in range(5):
            t = i / 4.0
            x = x0 + math.cos(angle) * length * t + RNG.uniform(-10, 10)
            y = y0 + math.sin(angle) * length * t + RNG.uniform(-8, 8)
            points.append((x, y))
        _draw_curve(glow, points, (96, 238, 255, RNG.randint(22, 48)), RNG.randint(1, 3), RNG.uniform(0.2, 0.9))

    base.alpha_composite(glow)


def _draw_projectors(base: Image.Image) -> None:
    metal = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(metal)
    sides = [
        [(34, 184), (92, 151), (155, 167), (136, 222), (58, 225)],
        [(WIDTH - 34, 184), (WIDTH - 92, 151), (WIDTH - 155, 167), (WIDTH - 136, 222), (WIDTH - 58, 225)],
    ]
    for idx, poly in enumerate(sides):
        draw.polygon(poly, fill=(22, 30, 34, 230), outline=(172, 115, 58, 210))
        inset = 14 if idx == 0 else -14
        draw.line([(poly[1][0] + inset, poly[1][1] + 9), (poly[3][0] + inset * 0.4, poly[3][1] - 9)], fill=(66, 215, 245, 130), width=3)
        for _ in range(26):
            cx = RNG.randint(min(p[0] for p in poly), max(p[0] for p in poly))
            cy = RNG.randint(min(p[1] for p in poly), max(p[1] for p in poly))
            draw.point((cx, cy), fill=(RNG.randint(120, 235), RNG.randint(90, 160), RNG.randint(50, 90), RNG.randint(45, 100)))
    base.alpha_composite(metal.filter(ImageFilter.GaussianBlur(0.15)))


def _draw_contact_light(base: Image.Image) -> None:
    glow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    for _ in range(38):
        x = RNG.uniform(90, WIDTH - 90)
        y = RNG.uniform(183, 223)
        radius = RNG.uniform(3.0, 12.0)
        color = RNG.choice([(255, 135, 42, 86), (108, 238, 255, 76), (255, 218, 122, 64)])
        draw.ellipse((x - radius, y - radius * 0.45, x + radius, y + radius * 0.45), fill=color)
    for _ in range(18):
        x = RNG.uniform(128, WIDTH - 128)
        y = RNG.uniform(190, 218)
        _draw_curve(
            glow,
            [(x - RNG.uniform(12, 38), y + RNG.uniform(-4, 4)), (x + RNG.uniform(34, 96), y + RNG.uniform(-6, 6))],
            (255, 128, 34, RNG.randint(36, 70)),
            RNG.randint(1, 3),
            RNG.uniform(1.2, 2.6),
        )
    base.alpha_composite(glow.filter(ImageFilter.GaussianBlur(0.5)))


def _apply_edge_alpha(image: Image.Image) -> Image.Image:
    px = image.load()
    for y in range(HEIGHT):
        for x in range(WIDTH):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (r, g, b, _clamp(a * _edge_fade(x, y)))
    return image


def render_barrier() -> Image.Image:
    base = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    wide_glow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(wide_glow)
    draw.ellipse((50, 18, WIDTH - 50, 250), fill=(64, 220, 255, 24))
    base.alpha_composite(wide_glow.filter(ImageFilter.GaussianBlur(18)))
    base.alpha_composite(_make_field())
    _draw_energy_edges(base)
    _draw_contact_light(base)
    _draw_projectors(base)

    core = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(core)
    for x in range(112, WIDTH - 111, 8):
        y = 202 + math.sin(x * 0.025) * 2.0
        alpha = int(42 + 28 * math.sin(x * 0.061 + 1.2))
        draw.line((x, y, x + 5, y + RNG.uniform(-1.2, 1.2)), fill=(150, 250, 255, max(12, alpha)), width=1)
    base.alpha_composite(core.filter(ImageFilter.GaussianBlur(0.45)))
    return _apply_edge_alpha(base)


def _foreground_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    pix = image.load()
    xs: list[int] = []
    ys: list[int] = []
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, _a = pix[x, y]
            mx = max(r, g, b)
            mn = min(r, g, b)
            avg = (r + g + b) / 3.0
            sat = mx - mn
            dark = max(0.0, 245.0 - avg)
            score = sat * 1.35 + dark * 0.78 + max(0, b - r) * 0.55 + max(0, r - b) * 0.35
            if score > 28.0:
                xs.append(x)
                ys.append(y)
    if not xs:
        return (0, 0, image.width, image.height)
    return (
        max(min(xs) - 45, 0),
        max(min(ys) - 40, 0),
        min(max(xs) + 45, image.width),
        min(max(ys) + 55, image.height),
    )


def _remove_checkerboard(source: Image.Image) -> Image.Image:
    bbox = _foreground_bbox(source)
    crop = source.crop(bbox).convert("RGBA")
    scale = min(940.0 / float(crop.width), 244.0 / float(crop.height))
    resized = crop.resize((max(1, int(crop.width * scale)), max(1, int(crop.height * scale))), Image.Resampling.LANCZOS).convert("RGBA")
    mask = Image.new("L", resized.size, 0)
    extracted = Image.new("RGBA", resized.size, (0, 0, 0, 0))
    src_px = resized.load()
    mask_px = mask.load()
    out_px = extracted.load()
    for y in range(resized.height):
        for x in range(resized.width):
            r, g, b, _a = src_px[x, y]
            mx = max(r, g, b)
            mn = min(r, g, b)
            avg = (r + g + b) / 3.0
            sat = mx - mn
            dark = max(0.0, 246.0 - avg)
            score = sat * 1.9 + dark * 1.12 + max(0, b - r) * 0.72 + max(0, r - b) * 0.55
            alpha = _clamp((score - 18.0) * 2.1)
            if b > r + 20 and g > r + 10:
                alpha = max(alpha, _clamp((b - r) * 2.5 + (g - r) * 1.1, 0, 210))
            if avg > 232 and sat < 18:
                alpha = 0
            if alpha <= 3:
                continue
            an = alpha / 255.0
            denom = max(an, 0.32)
            bg = 248.0
            rr = _clamp((r - bg * (1.0 - denom)) / denom)
            gg = _clamp((g - bg * (1.0 - denom)) / denom)
            bb = _clamp((b - bg * (1.0 - denom)) / denom)
            if bb >= gg >= rr:
                rr = _clamp(rr * 0.78)
                gg = _clamp(gg * 1.10)
                bb = _clamp(bb * 1.18)
            else:
                rr = _clamp(rr * 1.08)
                gg = _clamp(gg * 0.92)
                bb = _clamp(bb * 0.82)
            # Remove matte artifacts from the checkerboard extraction while
            # keeping the two dark side projectors.
            if 145 < x < resized.width - 145 and 40 < y < resized.height - 18 and rr + gg + bb < 46:
                alpha = 0
            if alpha <= 3:
                continue
            out_px[x, y] = (rr, gg, bb, alpha)
            mask_px[x, y] = alpha
    mask = mask.filter(ImageFilter.GaussianBlur(0.65))
    extracted.putalpha(mask)

    out = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    x0 = (WIDTH - resized.width) // 2
    y0 = (HEIGHT - resized.height) // 2
    out.alpha_composite(extracted, (x0, y0))
    out = _apply_edge_alpha(out)

    bloom = out.copy().filter(ImageFilter.GaussianBlur(5.0))
    bloom_px = bloom.load()
    for y in range(HEIGHT):
        for x in range(WIDTH):
            _r, _g, _b, a = bloom_px[x, y]
            bloom_px[x, y] = (80, 220, 255, int(a * 0.26))
    final = Image.alpha_composite(bloom, out)
    final_px = final.load()
    for y in range(HEIGHT):
        for x in range(WIDTH):
            r, g, b, a = final_px[x, y]
            if 132 < x < WIDTH - 132 and 22 < y < HEIGHT - 12 and a > 0 and r + g + b < 82:
                final_px[x, y] = (0, 0, 0, 0)
            if 150 < x < WIDTH - 150 and y > 138 and a > 0 and r + g + b < 210:
                final_px[x, y] = (0, 0, 0, 0)
    return final


def render_final_barrier() -> Image.Image:
    if IMAGEGEN_SOURCE.exists():
        return _remove_checkerboard(Image.open(IMAGEGEN_SOURCE).convert("RGBA"))
    return render_barrier()


def make_contact_sheet(before: Image.Image | None, after: Image.Image) -> None:
    CONTACT_SHEET.parent.mkdir(parents=True, exist_ok=True)
    thumb_w, thumb_h = 480, 130
    sheet = Image.new("RGBA", (1040, 370), (13, 18, 24, 255))
    draw = ImageDraw.Draw(sheet)
    draw.text((28, 22), "Defense Barrier Render Replacement", fill=(226, 234, 242, 255))
    if before is not None:
        sheet.alpha_composite(before.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS), (28, 78))
        draw.text((28, 220), "before: prototype frame / not runtime-friendly", fill=(150, 162, 174, 255))
    sheet.alpha_composite(after.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS), (532, 78))
    draw.text((532, 220), "after: raster energy-glass shield, transparent PNG", fill=(150, 162, 174, 255))
    draw.rectangle((532, 254, 1012, 322), outline=(80, 220, 245, 90), width=2)
    draw.text((552, 275), "Runtime path: assets/production/sprites/vfx/vfx_barrier_glass.png", fill=(190, 220, 228, 255))
    sheet.convert("RGB").save(CONTACT_SHEET, quality=95)


def main() -> None:
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    before_path = SOURCE_DIR / "vfx_barrier_glass_before.png"
    if before_path.exists():
        before = Image.open(before_path).convert("RGBA")
    else:
        before = Image.open(TARGET).convert("RGBA") if TARGET.exists() else None
        if before is not None:
            before.save(before_path)
    after = render_final_barrier()
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    after.save(TARGET)
    make_contact_sheet(before, after)
    prompt = (
        "Defense-line energy barrier for stylized semi-realistic 2.5D mobile tower defense. "
        "Transparent PNG, cyan energy-glass shield, subtle orange contact sparks, armored side projectors, "
        "soft bloom, grime, no text, no UI border, no hard vector placeholder lines."
    )
    (SOURCE_DIR / "barrier_glass_prompt.md").write_text(prompt + "\n", encoding="utf-8")
    manifest = {
        "task": "barrier_glass_redo_2026_07_09",
        "target": str(TARGET.relative_to(ROOT)),
        "source_image": str(IMAGEGEN_SOURCE.relative_to(ROOT)) if IMAGEGEN_SOURCE.exists() else "",
        "contact_sheet": str(CONTACT_SHEET.relative_to(ROOT)),
        "dimensions": [WIDTH, HEIGHT],
        "style": "raster rendered energy-glass defense barrier, no SVG/vector placeholder",
    }
    (SOURCE_DIR / "barrier_glass_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
