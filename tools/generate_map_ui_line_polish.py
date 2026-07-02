#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
UI_DIR = PROD / "sprites" / "ui"
SOURCE_DIR = PROD / "source_refs" / "generated"
CONTACT_DIR = PROD / "contact_sheets"
INDEX_PATH = PROD / "OUTSOURCER_ASSET_INDEX.json"
STAMP = "2026_07_02"
RNG = random.Random(2026070213)


def clamp(value: int) -> int:
	return max(0, min(255, value))


def gradient(size: tuple[int, int], top: tuple[int, int, int, int], bottom: tuple[int, int, int, int]) -> Image.Image:
	w, h = size
	img = Image.new("RGBA", size)
	pixels = img.load()
	for y in range(h):
		t = y / max(1, h - 1)
		row = tuple(int(top[i] * (1.0 - t) + bottom[i] * t) for i in range(4))
		for x in range(w):
			pixels[x, y] = row
	return img


def radial(size: tuple[int, int], center: tuple[float, float], color: tuple[int, int, int, int], radius: float, power: float = 2.0) -> Image.Image:
	w, h = size
	img = Image.new("RGBA", size, (0, 0, 0, 0))
	pixels = img.load()
	cx, cy = center
	for y in range(h):
		for x in range(w):
			d = math.hypot((x - cx) / max(radius, 1.0), (y - cy) / max(radius, 1.0))
			a = max(0.0, 1.0 - d) ** power
			if a > 0.0:
				pixels[x, y] = (color[0], color[1], color[2], int(color[3] * a))
	return img


def rounded_mask(size: tuple[int, int], box: tuple[int, int, int, int], radius: int) -> Image.Image:
	mask = Image.new("L", size, 0)
	draw = ImageDraw.Draw(mask)
	draw.rounded_rectangle(box, radius=radius, fill=255)
	return mask


def masked(size: tuple[int, int], mask: Image.Image, fill: Image.Image | tuple[int, int, int, int]) -> Image.Image:
	layer = fill.copy().convert("RGBA") if isinstance(fill, Image.Image) else Image.new("RGBA", size, fill)
	layer.putalpha(ImageChops.multiply(layer.getchannel("A"), mask))
	return layer


def add_noise(img: Image.Image, strength: int = 5, streaks: int = 10) -> Image.Image:
	out = img.convert("RGBA").copy()
	pixels = out.load()
	w, h = out.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = pixels[x, y]
			if a <= 0:
				continue
			n = RNG.randint(-strength, strength)
			pixels[x, y] = (clamp(r + n), clamp(g + n), clamp(b + n), a)
	draw = ImageDraw.Draw(out, "RGBA")
	for _ in range(streaks):
		x = RNG.randint(0, max(0, w - 1))
		y = RNG.randint(8, max(8, h - 9))
		length = RNG.randint(max(10, w // 12), max(12, w // 4))
		draw.line((x, y, min(w - 1, x + length), y + RNG.randint(-1, 1)), fill=(255, 245, 210, RNG.randint(8, 24)), width=1)
	return out


def soft_panel(size: tuple[int, int], radius: int, glow: str = "cyan", locked: bool = False) -> Image.Image:
	w, h = size
	img = Image.new("RGBA", size, (0, 0, 0, 0))
	outer = (5, 5, w - 6, h - 8)
	inner = (18, 16, w - 19, h - 19)
	accent = (78, 205, 220) if glow == "cyan" else (226, 150, 52)
	warm = (225, 137, 44)
	base_alpha = 206 if not locked else 154

	shadow_mask = rounded_mask(size, outer, radius)
	shadow = Image.new("RGBA", size, (0, 0, 0, 160))
	shadow.putalpha(shadow_mask.filter(ImageFilter.GaussianBlur(9)))
	img.alpha_composite(shadow, (0, 4))

	outer_fill = gradient(size, (30, 39, 43, base_alpha), (2, 5, 9, min(245, base_alpha + 32)))
	outer_fill.alpha_composite(radial(size, (w * 0.76, h * 0.22), (*accent, 44 if not locked else 20), w * 0.58))
	outer_fill.alpha_composite(radial(size, (w * 0.12, h * 0.82), (*warm, 34 if not locked else 16), w * 0.40))
	img.alpha_composite(masked(size, shadow_mask, add_noise(outer_fill, 4, 0)))

	inner_mask = rounded_mask(size, inner, max(8, radius - 10))
	glass = gradient(size, (18, 29, 34, 220 if not locked else 162), (1, 4, 8, 232 if not locked else 176))
	glass.alpha_composite(radial(size, (w * 0.70, h * 0.16), (*accent, 38 if not locked else 14), w * 0.42))
	glass.alpha_composite(radial(size, (w * 0.50, h * 0.82), (255, 160, 64, 18 if not locked else 8), w * 0.54))
	img.alpha_composite(masked(size, inner_mask, add_noise(glass, 3, 0)))

	draw = ImageDraw.Draw(img, "RGBA")
	draw.rounded_rectangle(outer, radius=radius, outline=(220, 230, 220, 22 if not locked else 12), width=1)
	corner_alpha = 92 if not locked else 42
	for sx, sy in [(inner[0], inner[1]), (inner[2], inner[1]), (inner[0], inner[3]), (inner[2], inner[3])]:
		dx = 1 if sx == inner[0] else -1
		dy = 1 if sy == inner[1] else -1
		draw.line((sx, sy, sx + dx * min(54, w // 8), sy), fill=(*accent, corner_alpha), width=2)
		draw.line((sx, sy, sx, sy + dy * min(34, h // 4)), fill=(*accent, corner_alpha), width=2)
	draw.rounded_rectangle(inner, radius=max(8, radius - 10), outline=(255, 240, 190, 14 if not locked else 6), width=1)
	return img


def pill(size: tuple[int, int]) -> Image.Image:
	w, h = size
	img = soft_panel(size, max(10, h // 3), "cyan")
	mask = rounded_mask(size, (6, 6, w - 7, h - 8), max(8, h // 3))
	img.putalpha(ImageChops.multiply(img.getchannel("A"), mask))
	return img


def premium_button(size: tuple[int, int], primary: bool) -> Image.Image:
	w, h = size
	img = Image.new("RGBA", size, (0, 0, 0, 0))
	radius = max(18, h // 3)
	outer = (8, 8, w - 9, h - 10)
	inner = (24, 22, w - 25, h - 25)
	accent = (240, 150, 42) if primary else (82, 190, 220)
	secondary = (72, 188, 128) if primary else (205, 128, 50)

	shadow_mask = rounded_mask(size, outer, radius)
	shadow = Image.new("RGBA", size, (0, 0, 0, 170))
	shadow.putalpha(shadow_mask.filter(ImageFilter.GaussianBlur(10)))
	img.alpha_composite(shadow, (0, 5))

	metal = gradient(size, (38, 42, 38, 236), (5, 8, 11, 246))
	metal.alpha_composite(radial(size, (w * 0.17, h * 0.20), (*accent, 56), w * 0.42))
	metal.alpha_composite(radial(size, (w * 0.86, h * 0.35), (*secondary, 46), w * 0.46))
	img.alpha_composite(masked(size, shadow_mask, add_noise(metal, 4, 0)))

	inner_mask = rounded_mask(size, inner, max(12, radius - 12))
	glass_top = (38, 72, 55, 228) if primary else (32, 48, 54, 222)
	glass_bottom = (8, 22, 17, 242) if primary else (7, 15, 20, 238)
	glass = gradient(size, glass_top, glass_bottom)
	glass.alpha_composite(radial(size, (w * 0.50, h * 0.20), (255, 235, 150, 34 if primary else 18), w * 0.58))
	glass.alpha_composite(radial(size, (w * 0.75, h * 0.72), (*accent, 30), w * 0.48))
	img.alpha_composite(masked(size, inner_mask, add_noise(glass, 3, 0)))

	draw = ImageDraw.Draw(img, "RGBA")
	draw.rounded_rectangle(outer, radius=radius, outline=(*accent, 96), width=3)
	for sx, sy in [(inner[0], inner[1]), (inner[2], inner[1]), (inner[0], inner[3]), (inner[2], inner[3])]:
		dx = 1 if sx == inner[0] else -1
		dy = 1 if sy == inner[1] else -1
		draw.line((sx, sy, sx + dx * 34, sy), fill=(255, 206, 118, 120), width=3)
		draw.line((sx, sy, sx, sy + dy * 22), fill=(255, 206, 118, 88), width=3)
	return img


def accent_strip(size: tuple[int, int]) -> Image.Image:
	w, h = size
	img = Image.new("RGBA", size, (0, 0, 0, 0))
	draw = ImageDraw.Draw(img, "RGBA")
	draw.rounded_rectangle((w // 2 - 4, 4, w // 2 + 4, h - 5), radius=5, fill=(255, 255, 255, 200))
	glow = img.filter(ImageFilter.GaussianBlur(5))
	glow.putalpha(glow.getchannel("A").point(lambda v: int(v * 0.48)))
	return Image.alpha_composite(glow, img)


def save(path: Path, img: Image.Image) -> str:
	path.parent.mkdir(parents=True, exist_ok=True)
	img.save(path)
	return str(path.relative_to(ROOT))


def star_points(cx: float, cy: float, outer: float, inner: float, rotation: float = -math.pi / 2.0) -> list[tuple[float, float]]:
	points: list[tuple[float, float]] = []
	for i in range(10):
		radius = outer if i % 2 == 0 else inner
		angle = rotation + i * math.pi / 5.0
		points.append((cx + math.cos(angle) * radius, cy + math.sin(angle) * radius))
	return points


def draw_glow_poly(base: Image.Image, points: list[tuple[float, float]], color: tuple[int, int, int, int], blur: float) -> None:
	layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
	draw = ImageDraw.Draw(layer, "RGBA")
	draw.polygon(points, fill=color)
	layer = layer.filter(ImageFilter.GaussianBlur(blur))
	base.alpha_composite(layer)


def star_badge(filled: bool) -> Image.Image:
	size = (256, 256)
	img = Image.new("RGBA", size, (0, 0, 0, 0))
	cx, cy = 128, 130
	outer_points = star_points(cx, cy, 94, 42)
	inner_points = star_points(cx, cy + 2, 68, 30)
	metal = (244, 181, 50, 255) if filled else (132, 150, 156, 245)
	edge = (255, 226, 110, 255) if filled else (205, 226, 232, 210)
	shadow = star_points(cx + 4, cy + 8, 96, 43)
	draw_glow_poly(img, outer_points, (255, 166, 28, 86) if filled else (94, 214, 232, 48), 14)
	draw_glow_poly(img, shadow, (0, 0, 0, 150), 5)
	draw = ImageDraw.Draw(img, "RGBA")
	for offset, color in [(0, (92, 55, 14, 255) if filled else (34, 48, 54, 230)), (-5, edge)]:
		pts = star_points(cx, cy + offset, 94, 42)
		draw.polygon(pts, fill=color)
	if filled:
		grad = gradient(size, (255, 224, 88, 255), (192, 102, 19, 255))
		mask = Image.new("L", size, 0)
		ImageDraw.Draw(mask).polygon(inner_points, fill=255)
		img.alpha_composite(masked(size, mask, grad))
		draw.line(outer_points + [outer_points[0]], fill=(255, 242, 176, 190), width=3, joint="curve")
		draw.line(star_points(cx, cy + 2, 66, 28) + [star_points(cx, cy + 2, 66, 28)[0]], fill=(98, 47, 6, 92), width=2, joint="curve")
	else:
		draw.line(outer_points + [outer_points[0]], fill=edge, width=8, joint="curve")
		draw.line(inner_points + [inner_points[0]], fill=(32, 44, 49, 196), width=5, joint="curve")
		draw_glow_poly(img, star_points(cx, cy, 78, 34), (255, 255, 255, 22), 10)
	return add_noise(img, 3, 0)


def coin_badge() -> Image.Image:
	size = (256, 256)
	img = Image.new("RGBA", size, (0, 0, 0, 0))
	draw = ImageDraw.Draw(img, "RGBA")
	draw.ellipse((38, 44, 218, 224), fill=(0, 0, 0, 130))
	glow = Image.new("RGBA", size, (0, 0, 0, 0))
	ImageDraw.Draw(glow, "RGBA").ellipse((32, 28, 224, 220), fill=(255, 157, 38, 86))
	img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(14)))
	coin_mask = Image.new("L", size, 0)
	ImageDraw.Draw(coin_mask).ellipse((34, 26, 222, 214), fill=255)
	body = gradient(size, (255, 219, 87, 255), (170, 89, 20, 255))
	body.alpha_composite(radial(size, (94, 70), (255, 255, 210, 132), 92, 1.4))
	img.alpha_composite(masked(size, coin_mask, add_noise(body, 4, 0)))
	draw.ellipse((34, 26, 222, 214), outline=(255, 236, 132, 230), width=7)
	draw.ellipse((66, 60, 190, 184), outline=(114, 62, 12, 160), width=10)
	draw.ellipse((78, 72, 178, 172), outline=(255, 220, 88, 168), width=5)
	draw.line((128, 72, 128, 172), fill=(88, 45, 10, 145), width=5)
	draw.line((132, 72, 132, 172), fill=(255, 232, 116, 120), width=2)
	return img


def star_currency_badge() -> Image.Image:
	img = soft_panel((256, 256), 34, "orange")
	draw = ImageDraw.Draw(img, "RGBA")
	draw.rounded_rectangle((48, 48, 208, 208), radius=36, outline=(252, 180, 46, 132), width=5)
	star = star_badge(True).resize((150, 150), Image.Resampling.LANCZOS)
	img.alpha_composite(star, (53, 48))
	draw.ellipse((102, 104, 154, 156), outline=(98, 47, 7, 110), width=4)
	return img


def contact_sheet(paths: list[Path]) -> Path:
	card_w, card_h = 360, 170
	gap = 18
	margin = 24
	cols = 2
	rows = math.ceil(len(paths) / cols)
	sheet = Image.new("RGBA", (margin * 2 + card_w * cols + gap * (cols - 1), margin * 2 + card_h * rows + gap * max(0, rows - 1)), (10, 15, 20, 255))
	draw = ImageDraw.Draw(sheet)
	for idx, path in enumerate(paths):
		col = idx % 2
		row = idx // 2
		x = margin + col * (card_w + gap)
		y = margin + row * (card_h + gap)
		draw.rounded_rectangle((x, y, x + card_w, y + card_h), radius=8, fill=(16, 24, 32), outline=(72, 92, 104))
		img = Image.open(path).convert("RGBA")
		img.thumbnail((card_w - 28, 100), Image.Resampling.LANCZOS)
		sheet.alpha_composite(img, (x + (card_w - img.width) // 2, y + 18))
		draw.text((x + 14, y + 124), path.name, fill=(220, 226, 230))
	out = CONTACT_DIR / f"contact_map_ui_line_polish_{STAMP}.png"
	out.parent.mkdir(parents=True, exist_ok=True)
	sheet.convert("RGB").save(out)
	return out


def update_index(spec_path: Path, sheet_path: Path, written: list[str]) -> None:
	data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
	overrides = data.setdefault("owner_directed_generated_overrides", [])
	entry = {
		"path": "sprites/ui/map_line_polish",
		"source": str(spec_path.relative_to(PROD)),
		"derived": str(sheet_path.relative_to(PROD)),
		"reason": "Owner flagged the map interface linework as ugly; this pass replaces dense geometric line styling with softer raster glass skins while preserving map data and navigation behavior.",
	}
	if entry not in overrides:
		overrides.append(entry)
	data[f"map_ui_line_polish_{STAMP}"] = {
		"status": "integrated",
		"paths": written,
		"quality_bar": "Raster PNG skins, softer glass panels, reduced visible line density, no SVG/vector assets.",
	}
	INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
	written: list[str] = []
	outputs = {
		"ui_map_level_card_skin.png": soft_panel((1024, 156), 22, "cyan"),
		"ui_map_level_card_locked_skin.png": soft_panel((1024, 156), 22, "cyan", True),
		"ui_map_nav_card_skin.png": soft_panel((320, 142), 18, "cyan"),
		"ui_map_resource_chip_skin.png": soft_panel((512, 150), 22, "orange"),
		"ui_map_pill_skin.png": pill((320, 74)),
		"ui_map_index_plate_skin.png": soft_panel((140, 104), 18, "cyan"),
		"ui_map_deploy_pill_skin.png": pill((300, 72)),
		"ui_map_accent_strip.png": accent_strip((26, 118)),
		"ui_button_primary.png": premium_button((512, 160), True),
		"ui_button_secondary.png": premium_button((512, 160), False),
		"ui_modal_button_primary.png": premium_button((512, 160), True),
		"ui_modal_button_secondary.png": premium_button((512, 160), False),
		"icon_currency_gold.png": coin_badge(),
		"icon_currency_star.png": star_currency_badge(),
		"ui_star_filled.png": star_badge(True),
		"ui_star_empty.png": star_badge(False),
	}
	paths: list[Path] = []
	for name, img in outputs.items():
		path = UI_DIR / name
		written.append(save(path, img))
		paths.append(path)
	sheet_path = contact_sheet(paths)
	spec = {
		"stamp": STAMP,
		"intent": "Reduce ugly line-heavy map UI by replacing visible geometric line styling with authored raster HUD skins.",
		"outputs": written,
		"contact_sheet": str(sheet_path.relative_to(ROOT)),
		"notes": [
			"No gameplay data, level logic, unlock logic, or economy values changed.",
			"Generated outputs are transparent PNG skins, not SVG/vector assets.",
		],
	}
	spec_path = SOURCE_DIR / f"map_ui_line_polish_spec_{STAMP}.json"
	spec_path.parent.mkdir(parents=True, exist_ok=True)
	spec_path.write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	update_index(spec_path, sheet_path, written)
	print(f"Generated {len(written)} map UI skins")
	print(sheet_path)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
