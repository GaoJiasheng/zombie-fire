#!/usr/bin/env python3
from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
PROJECTILE_DIR = PROD / "sprites" / "projectiles"
SOURCE_DIR = PROD / "source_refs" / "generated"
INDEX_PATH = PROD / "OUTSOURCER_ASSET_INDEX.json"

SIZE = 256


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_color.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha)


def layer() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def composite(base: Image.Image, top: Image.Image) -> None:
    base.alpha_composite(top)


def blur_shape(base: Image.Image, draw_fn, blur: float, alpha_mult: float = 1.0) -> None:
    fx = layer()
    draw_fn(ImageDraw.Draw(fx, "RGBA"))
    if alpha_mult < 1.0:
        pixels = fx.load()
        for y in range(SIZE):
            for x in range(SIZE):
                r, g, b, a = pixels[x, y]
                if a:
                    pixels[x, y] = (r, g, b, int(a * alpha_mult))
    composite(base, fx.filter(ImageFilter.GaussianBlur(blur)))


def glow(base: Image.Image, box: tuple[int, int, int, int], color: tuple[int, int, int, int], blur: float) -> None:
    def draw(drawer: ImageDraw.ImageDraw) -> None:
        drawer.ellipse(box, fill=color)

    blur_shape(base, draw, blur)


def line_glow(base: Image.Image, points: list[tuple[float, float]], color: tuple[int, int, int, int], width: int, blur: float) -> None:
    def draw(drawer: ImageDraw.ImageDraw) -> None:
        drawer.line(points, fill=color, width=width, joint="curve")

    blur_shape(base, draw, blur)


def draw_capsule(
    img: Image.Image,
    body: tuple[int, int, int, int],
    nose: tuple[tuple[int, int], ...],
    shell_top: str,
    shell_mid: str,
    shell_bottom: str,
    accent: str,
    glow_color: str,
    tail_color: str,
) -> None:
    d = ImageDraw.Draw(img, "RGBA")
    glow(img, (body[0] - 28, body[1] - 32, nose[1][0] + 42, body[3] + 34), rgba(glow_color, 95), 18)
    for i in range(18):
        t = i / 17.0
        y = int(body[1] + t * (body[3] - body[1]))
        if t < 0.28:
            color = rgba(shell_top, 235)
        elif t < 0.72:
            color = rgba(shell_mid, 245)
        else:
            color = rgba(shell_bottom, 245)
        d.rounded_rectangle((body[0], y - 3, body[2], y + 5), radius=22, fill=color)
    d.rounded_rectangle(body, radius=26, outline=rgba("#eef6ff", 180), width=2)
    d.polygon(nose, fill=rgba(shell_top, 245), outline=rgba("#f8fbff", 190))
    d.polygon(((nose[0][0] + 2, nose[0][1] + 8), nose[1], (nose[2][0] + 2, nose[2][1] - 8)), fill=rgba(accent, 120))
    d.rounded_rectangle((body[0] - 14, body[1] + 12, body[0] + 14, body[3] - 12), radius=8, fill=rgba(shell_bottom, 210), outline=rgba("#c7d2e2", 150), width=1)
    for x in (body[0] + 26, body[2] - 24):
        d.rounded_rectangle((x, body[1] + 7, x + 7, body[3] - 7), radius=3, fill=rgba(accent, 190))
    d.line((body[0] + 18, body[1] + 13, body[2] - 20, body[1] + 10), fill=rgba("#ffffff", 92), width=3)
    d.line((body[0] + 20, body[3] - 12, body[2] - 16, body[3] - 8), fill=rgba("#000000", 90), width=3)
    d.polygon(((body[0] - 22, 116), (body[0] + 6, 103), (body[0] + 6, 153), (body[0] - 22, 140)), fill=rgba(tail_color, 160))
    line_glow(img, [(body[0] - 54, 128), (body[0] - 8, 128)], rgba(tail_color, 170), 18, 10)
    d.line((body[0] - 48, 128, body[0] - 4, 128), fill=rgba("#fff4aa", 180), width=3)


def physical() -> Image.Image:
    img = layer()
    draw_capsule(img, (64, 96, 181, 160), ((176, 94), (229, 128), (176, 162)), "#f1f5f8", "#89919d", "#323942", "#ff8a30", "#d9dee5", "#d9dee5")
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse((188, 118, 221, 139), fill=rgba("#ffffff", 165))
    return img


def fire() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img, "RGBA")
    glow(img, (30, 58, 242, 198), rgba("#ff5722", 120), 22)
    for r, a in [(42, 145), (30, 190), (18, 230)]:
        d.ellipse((148 - r, 128 - r, 148 + r, 128 + r), fill=rgba("#ff6a20", a))
    draw_capsule(img, (64, 90, 178, 166), ((172, 88), (230, 128), (172, 168)), "#ffd479", "#d74718", "#4a1510", "#ffb000", "#ff5722", "#ff7b1f")
    d.polygon(((31, 128), (68, 104), (58, 124), (87, 128), (58, 134), (68, 154)), fill=rgba("#fff06b", 230))
    d.polygon(((18, 128), (65, 91), (52, 124), (91, 128), (52, 132), (65, 165)), fill=rgba("#ff5722", 155))
    return img


def ice() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img, "RGBA")
    glow(img, (38, 50, 238, 206), rgba("#46c6ff", 125), 18)
    shard = [(48, 132), (92, 76), (176, 68), (232, 126), (174, 184), (92, 178)]
    d.polygon(shard, fill=rgba("#7be6ff", 218), outline=rgba("#d9fbff", 230))
    d.polygon([(92, 76), (134, 126), (176, 68)], fill=rgba("#d5fbff", 185))
    d.polygon([(92, 178), (134, 126), (174, 184)], fill=rgba("#177fb2", 175))
    d.polygon([(48, 132), (134, 126), (92, 76)], fill=rgba("#49c9ff", 170))
    d.line((82, 94, 210, 126), fill=rgba("#ffffff", 150), width=3)
    for y in (102, 132, 160):
        d.line((28, y, 74, y - 10), fill=rgba("#95efff", 125), width=5)
    return img


def lightning() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img, "RGBA")
    glow(img, (36, 42, 236, 214), rgba("#c77dff", 130), 20)
    glow(img, (74, 82, 210, 172), rgba("#ffe14d", 125), 12)
    draw_capsule(img, (72, 96, 176, 160), ((170, 91), (230, 128), (170, 165)), "#fff5a8", "#7b42dc", "#26194c", "#ffe14d", "#c77dff", "#ffe14d")
    bolts = [
        [(36, 118), (74, 111), (58, 130), (104, 122)],
        [(50, 146), (95, 136), (78, 157), (126, 144)],
        [(124, 72), (146, 111), (132, 105), (162, 154)],
    ]
    for pts in bolts:
        d.line(pts, fill=rgba("#ffe14d", 230), width=5, joint="curve")
        d.line(pts, fill=rgba("#ffffff", 200), width=2, joint="curve")
    return img


def poison() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img, "RGBA")
    glow(img, (42, 46, 236, 210), rgba("#8be04e", 145), 22)
    draw_capsule(img, (66, 91, 178, 165), ((174, 88), (229, 128), (174, 168)), "#e7ffd3", "#42e423", "#173815", "#8be04e", "#8be04e", "#8be04e")
    d.rounded_rectangle((84, 104, 158, 152), radius=20, fill=rgba("#58ff2e", 168), outline=rgba("#caff9d", 170), width=2)
    for cx, cy, r in [(112, 114, 5), (138, 136, 7), (101, 142, 4), (151, 112, 4)]:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgba("#d7ff9c", 170))
    for x, y, r, a in [(45, 106, 10, 150), (34, 141, 7, 130), (55, 158, 5, 110)]:
        d.ellipse((x - r, y - r, x + r, y + r), fill=rgba("#8be04e", a))
    return img


def heavy_charge() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img, "RGBA")
    glow(img, (32, 44, 238, 212), rgba("#ffb020", 125), 24)
    glow(img, (78, 72, 207, 184), rgba("#ffffff", 150), 10)
    draw_capsule(img, (60, 86, 184, 170), ((176, 82), (235, 128), (176, 174)), "#fff0a8", "#4d5560", "#15191f", "#ff8a00", "#ff9d1f", "#ff8a00")
    for r, a in [(54, 90), (38, 125), (22, 190)]:
        d.ellipse((132 - r, 128 - r, 132 + r, 128 + r), outline=rgba("#ffcf54", a), width=3)
    d.ellipse((118, 114, 146, 142), fill=rgba("#ffffff", 225))
    return img


def acid_spit() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img, "RGBA")
    glow(img, (30, 44, 230, 210), rgba("#75ff31", 135), 18)
    blobs = [(88, 128, 43, "#65ff2a", 210), (130, 115, 34, "#bcff55", 170), (164, 139, 39, "#33b923", 180)]
    for cx, cy, r, color, alpha in blobs:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgba(color, alpha), outline=rgba("#d7ff87", 130), width=2)
    d.polygon(((178, 92), (232, 128), (178, 165)), fill=rgba("#aaff31", 145), outline=rgba("#efffb0", 130))
    for cx, cy, r in [(64, 94, 8), (51, 154, 6), (39, 125, 5), (112, 84, 4)]:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgba("#c8ff5a", 150))
    return img


def split_mini() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img, "RGBA")
    glow(img, (55, 82, 218, 174), rgba("#ffb43d", 90), 13)
    shard = [(44, 132), (106, 95), (218, 124), (116, 158)]
    d.polygon(shard, fill=rgba("#f6c46b", 235), outline=rgba("#fff3bc", 180))
    d.polygon([(106, 95), (148, 126), (218, 124)], fill=rgba("#fff0af", 185))
    d.polygon([(44, 132), (148, 126), (116, 158)], fill=rgba("#9b5b22", 195))
    d.line((72, 130, 192, 124), fill=rgba("#fff7c8", 150), width=3)
    return img


def rail_slug() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img, "RGBA")
    line_glow(img, [(22, 128), (238, 128)], rgba("#5af4ff", 120), 22, 12)
    d.polygon(((32, 128), (84, 104), (203, 111), (240, 128), (203, 145), (84, 152)), fill=rgba("#8ea2b8", 230), outline=rgba("#e8faff", 190))
    d.polygon(((84, 104), (132, 126), (203, 111)), fill=rgba("#e4f7ff", 160))
    d.polygon(((84, 152), (132, 130), (203, 145)), fill=rgba("#202a34", 210))
    d.line((38, 128, 236, 128), fill=rgba("#dfffff", 210), width=3)
    d.line((75, 112, 198, 117), fill=rgba("#5af4ff", 190), width=5)
    d.line((75, 144, 198, 139), fill=rgba("#1a7e9b", 160), width=5)
    return img


def scatter_pellet() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img, "RGBA")
    glow(img, (62, 76, 203, 178), rgba("#ffc257", 95), 12)
    d.ellipse((72, 92, 184, 164), fill=rgba("#c9d0d9", 230), outline=rgba("#fff3c7", 150), width=2)
    d.ellipse((108, 101, 171, 138), fill=rgba("#fff2c2", 132))
    d.pieslice((70, 94, 184, 166), 35, 160, fill=rgba("#fbfbff", 70))
    d.pieslice((70, 94, 184, 166), 205, 330, fill=rgba("#20252c", 110))
    d.line((38, 128, 85, 128), fill=rgba("#ffb43d", 140), width=8)
    return img


def plasma_orb() -> Image.Image:
    img = layer()
    d = ImageDraw.Draw(img, "RGBA")
    glow(img, (26, 28, 238, 228), rgba("#c77dff", 145), 24)
    glow(img, (75, 70, 195, 190), rgba("#ffffff", 170), 12)
    d.ellipse((72, 72, 192, 192), fill=rgba("#8d35ff", 168), outline=rgba("#ffe7ff", 190), width=3)
    d.ellipse((99, 99, 165, 165), fill=rgba("#fff0ff", 200))
    d.arc((48, 66, 215, 186), 205, 25, fill=rgba("#ff8cff", 200), width=7)
    d.arc((60, 48, 208, 210), 330, 150, fill=rgba("#ffb020", 170), width=5)
    for angle in range(-45, 46, 30):
        y = 128 + int(math.sin(math.radians(angle)) * 34)
        d.line((42, y, 88, 128), fill=rgba("#c77dff", 95), width=5)
    return img


ASSETS = {
    "proj_bullet_physical.png": {"kind": "physical", "fn": physical, "desc": "steel jacket physical round"},
    "proj_bullet_fire.png": {"kind": "fire", "fn": fire, "desc": "orange flame round with molten core"},
    "proj_bullet_ice.png": {"kind": "ice", "fn": ice, "desc": "faceted blue cryo shard"},
    "proj_bullet_lightning.png": {"kind": "lightning", "fn": lightning, "desc": "purple-yellow electric dart"},
    "proj_bullet_poison.png": {"kind": "poison", "fn": poison, "desc": "toxic glass capsule with liquid bubbles"},
    "proj_heavy_charge.png": {"kind": "heavy", "fn": heavy_charge, "desc": "atomic-style heavy energy charge"},
    "proj_acid_spit.png": {"kind": "acid", "fn": acid_spit, "desc": "corrosive acid globule"},
    "proj_split_mini.png": {"kind": "split", "fn": split_mini, "desc": "small split shard"},
    "proj_rail_slug.png": {"kind": "rail", "fn": rail_slug, "desc": "cyan railgun lance slug"},
    "proj_scatter_pellet.png": {"kind": "scatter", "fn": scatter_pellet, "desc": "compact scattergun tungsten pellet"},
    "proj_plasma_orb.png": {"kind": "plasma", "fn": plasma_orb, "desc": "magenta plasma orb"},
}


def save_assets() -> None:
    PROJECTILE_DIR.mkdir(parents=True, exist_ok=True)
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    images: dict[str, Image.Image] = {}
    for filename, spec in ASSETS.items():
        img = clean_alpha_edges(spec["fn"]())
        images[filename] = img
        img.save(PROJECTILE_DIR / filename)
    save_preview(images)
    save_source_spec()
    update_asset_index()


def clean_alpha_edges(img: Image.Image) -> Image.Image:
    cleaned = img.copy()
    pixels = cleaned.load()
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = pixels[x, y]
            edge_dist = min(x, y, SIZE - 1 - x, SIZE - 1 - y)
            if a <= 8:
                pixels[x, y] = (0, 0, 0, 0)
            elif edge_dist < 8:
                fade = max(edge_dist / 8.0, 0.0)
                pixels[x, y] = (r, g, b, int(a * fade))
    return cleaned


def save_preview(images: dict[str, Image.Image]) -> None:
    cell_w, cell_h = 220, 190
    cols = 4
    rows = math.ceil(len(images) / cols)
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (8, 11, 16, 255))
    draw = ImageDraw.Draw(sheet, "RGBA")
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 18)
    except OSError:
        font = ImageFont.load_default()
    for idx, (filename, img) in enumerate(images.items()):
        x = (idx % cols) * cell_w
        y = (idx // cols) * cell_h
        draw.rounded_rectangle((x + 10, y + 10, x + cell_w - 10, y + cell_h - 10), radius=10, fill=(12, 18, 26, 255), outline=(86, 120, 150, 180), width=2)
        thumb = img.resize((144, 144), Image.Resampling.LANCZOS)
        sheet.alpha_composite(thumb, (x + 38, y + 18))
        draw.text((x + 16, y + 154), filename.replace(".png", ""), fill=(214, 232, 242, 255), font=font)
    sheet.save(SOURCE_DIR / "projectile_3d_projectile_sheet.png")


def save_source_spec() -> None:
    spec = {
        "id": "projectile_3d_projectile_set",
        "generated_by": "tools/generate_projectile_visuals.py",
        "style": "2.5D cyberpunk ruined-city projectile sprites, right-facing baseline, transparent PNG",
        "runtime_rule": "SPRITE_FORWARD_ANGLE is 0.0, so all projectile sprites face right before Godot rotates them to velocity.",
        "assets": [
            {
                "path": f"sprites/projectiles/{filename}",
                "kind": data["kind"],
                "description": data["desc"],
            }
            for filename, data in ASSETS.items()
        ],
        "prompt_reference": (
            "Create a unified set of right-facing 2.5D cyberpunk projectile sprites for a vertical mobile zombie defense game: "
            "physical steel round, fire round, ice shard, lightning dart, poison capsule, heavy energy charge, acid globule, "
            "split shard, railgun slug, and plasma orb. Transparent background, crisp alpha, readable at small size, "
            "upper-right rim light, saturated element color, no UI frame and no text."
        ),
    }
    (SOURCE_DIR / "projectile_3d_projectile_spec.json").write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def update_asset_index() -> None:
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    data["counts"]["total_files"] = sum(1 for path in PROD.rglob("*") if path.is_file())
    overrides = data.setdefault("owner_directed_generated_overrides", [])
    overrides = [item for item in overrides if item.get("path") != "sprites/projectiles"]
    overrides.append(
        {
            "path": "sprites/projectiles",
            "source": "source_refs/generated/projectile_3d_projectile_spec.json",
            "derived": "source_refs/generated/projectile_3d_projectile_sheet.png",
            "reason": "Owner requested all bullet/ammo types to read as flashier 3D-style projectile models with distinct elemental and weapon-specific silhouettes.",
        }
    )
    data["owner_directed_generated_overrides"] = overrides
    INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    save_assets()
