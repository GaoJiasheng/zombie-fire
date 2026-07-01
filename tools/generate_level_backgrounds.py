#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
BG_DIR = PROD / "sprites" / "backgrounds"
ENV_DIR = PROD / "environment"
CONTACT_DIR = PROD / "contact_sheets"
SOURCE_DIR = PROD / "source_refs" / "generated"
W, H = 1080, 1920


BACKGROUND_SPECS = [
	{
		"env": "env_lava_foundry",
		"bg": "bg_lava_foundry",
		"title": "熔岩铸厂",
		"range": "001-010",
		"base": "bg_military.png",
		"base_alt": "bg_biolab.png",
		"kind": "lava",
		"accent": "#F37525",
		"secondary": "#FFC45E",
		"tint": "#2A1008",
		"description": "熔岩铸厂、焦黑金属、熔沟、破损锻造设备",
	},
	{
		"env": "env_glacier_pass",
		"bg": "bg_glacier_pass",
		"title": "冰川断桥",
		"range": "011-020",
		"base": "bg_city_ruins.png",
		"base_alt": "bg_subway.png",
		"kind": "ice",
		"accent": "#78DFFF",
		"secondary": "#E8FAFF",
		"tint": "#082239",
		"description": "冰封城市断桥、冻裂路面、冰崖、寒雾",
	},
	{
		"env": "env_abandoned_factory",
		"bg": "bg_abandoned_factory",
		"title": "废弃工厂",
		"range": "021-030",
		"base": "bg_subway.png",
		"base_alt": "bg_military.png",
		"kind": "factory",
		"accent": "#D88937",
		"secondary": "#5AD6E8",
		"tint": "#11161A",
		"description": "废弃工厂、传送带、吊臂、锈蚀机台",
	},
	{
		"env": "env_toxic_biolab",
		"bg": "bg_toxic_biolab",
		"title": "毒液生化舱",
		"range": "031-040",
		"base": "bg_biolab.png",
		"base_alt": "bg_subway.png",
		"kind": "toxic",
		"accent": "#36F26E",
		"secondary": "#9DFF83",
		"tint": "#062314",
		"description": "破损生化实验室、毒液池、培养舱、管线泄漏",
	},
	{
		"env": "env_storm_substation",
		"bg": "bg_storm_substation",
		"title": "雷暴变电站",
		"range": "041-050",
		"base": "bg_military.png",
		"base_alt": "bg_subway.png",
		"kind": "storm",
		"accent": "#FFE24A",
		"secondary": "#7B64FF",
		"tint": "#0A1430",
		"description": "雷暴变电站、特斯拉塔、变压器、电弧",
	},
	{
		"env": "env_flooded_subway",
		"bg": "bg_flooded_subway",
		"title": "沉没地铁",
		"range": "051-060",
		"base": "bg_subway.png",
		"base_alt": "bg_city_ruins.png",
		"kind": "water",
		"accent": "#45D6FF",
		"secondary": "#E6B569",
		"tint": "#06212B",
		"description": "积水地铁站、轨道、站台、反光水面",
	},
	{
		"env": "env_desert_refinery",
		"bg": "bg_desert_refinery",
		"title": "沙暴炼油区",
		"range": "061-070",
		"base": "bg_military.png",
		"base_alt": "bg_city_ruins.png",
		"kind": "desert",
		"accent": "#E8A64A",
		"secondary": "#5AD8D4",
		"tint": "#3A2411",
		"description": "沙暴炼油区、管线、油罐、燃烧塔、沙尘",
	},
	{
		"env": "env_void_cathedral",
		"bg": "bg_void_cathedral",
		"title": "虚空圣堂",
		"range": "071-080",
		"base": "bg_main_menu.png",
		"base_alt": "bg_biolab.png",
		"kind": "void",
		"accent": "#9C6DFF",
		"secondary": "#FF6BE7",
		"tint": "#100A25",
		"description": "崩塌圣堂、黑曜石拱门、裂隙能量、石板地面",
	},
	{
		"env": "env_orbital_ruins",
		"bg": "bg_orbital_ruins",
		"title": "轨道升降遗址",
		"range": "081-090",
		"base": "bg_military.png",
		"base_alt": "bg_level_map.png",
		"kind": "orbital",
		"accent": "#C9E6FF",
		"secondary": "#F6A642",
		"tint": "#0A1722",
		"description": "轨道升降机遗址、巨大缆索、航天残骸、冷色信标",
	},
	{
		"env": "env_apex_core",
		"bg": "bg_apex_core",
		"title": "终局核心",
		"range": "091-099",
		"base": "bg_biolab.png",
		"base_alt": "bg_level_map.png",
		"kind": "core",
		"accent": "#F6B63D",
		"secondary": "#72EAFF",
		"tint": "#160D05",
		"description": "终局反应堆核心、黑金装甲地面、等离子管线",
	},
]


def _hex(color: str, alpha: int = 255) -> tuple[int, int, int, int]:
	color = color.lstrip("#")
	return (int(color[0:2], 16), int(color[2:4], 16), int(color[4:6], 16), alpha)


def _rgb(color: str) -> tuple[int, int, int]:
	r, g, b, _a = _hex(color)
	return r, g, b


def _new_rgba(color: tuple[int, int, int, int] = (0, 0, 0, 0)) -> Image.Image:
	return Image.new("RGBA", (W, H), color)


def _cover(path: Path, focus_x: float = 0.5, focus_y: float = 0.52) -> Image.Image:
	img = Image.open(path).convert("RGB")
	scale = max(W / img.width, H / img.height)
	size = (int(img.width * scale + 0.5), int(img.height * scale + 0.5))
	img = img.resize(size, Image.Resampling.LANCZOS)
	left = int((size[0] - W) * focus_x)
	top = int((size[1] - H) * focus_y)
	left = max(0, min(left, size[0] - W))
	top = max(0, min(top, size[1] - H))
	return img.crop((left, top, left + W, top + H)).convert("RGBA")


def _grade(img: Image.Image, tint: str, accent: str, contrast: float = 1.12, color: float = 1.1, brightness: float = 0.9) -> Image.Image:
	img = ImageEnhance.Contrast(img).enhance(contrast)
	img = ImageEnhance.Color(img).enhance(color)
	img = ImageEnhance.Brightness(img).enhance(brightness)
	overlay = Image.new("RGBA", (W, H), _hex(tint, 98))
	img = Image.alpha_composite(img, overlay)
	glaze = _new_rgba()
	d = ImageDraw.Draw(glaze)
	d.rectangle([0, 0, W, 470], fill=(0, 0, 0, 72))
	d.rectangle([0, 1500, W, H], fill=(0, 0, 0, 62))
	d.rectangle([0, 0, 80, H], fill=(0, 0, 0, 56))
	d.rectangle([1000, 0, W, H], fill=(0, 0, 0, 56))
	d.line([(0, 1480), (W, 1480)], fill=_hex(accent, 42), width=3)
	return Image.alpha_composite(img, glaze)


def _lane_edges(y: float) -> tuple[int, int]:
	t = max(0.0, min(1.0, y / H))
	left = int(360 + (180 - 360) * t)
	right = int(720 + (900 - 720) * t)
	return left, right


def _poly_line(draw: ImageDraw.ImageDraw, pts: list[tuple[float, float]], fill: tuple[int, int, int, int], width: int) -> None:
	for a, b in zip(pts, pts[1:]):
		draw.line([a, b], fill=fill, width=width)


def _glow_line(layer: Image.Image, pts: list[tuple[float, float]], color: str, width: int, glow: int, alpha: int = 180) -> None:
	soft = _new_rgba()
	d = ImageDraw.Draw(soft)
	for g in range(4, 0, -1):
		_poly_line(d, pts, _hex(color, int(alpha * 0.08 * g)), width + glow * g)
	soft = soft.filter(ImageFilter.GaussianBlur(glow))
	layer.alpha_composite(soft)
	_poly_line(ImageDraw.Draw(layer), pts, _hex(color, alpha), width)


def _draw_ellipse_glow(layer: Image.Image, box: tuple[int, int, int, int], color: str, alpha: int = 150, blur: int = 14) -> None:
	soft = _new_rgba()
	d = ImageDraw.Draw(soft)
	d.ellipse(box, fill=_hex(color, alpha))
	layer.alpha_composite(soft.filter(ImageFilter.GaussianBlur(blur)))
	ImageDraw.Draw(layer).ellipse(box, outline=_hex(color, min(240, alpha + 70)), width=3)


def _draw_battle_lane(img: Image.Image, rng: random.Random, spec: dict) -> None:
	kind = spec["kind"]
	accent = spec["accent"]
	layer = _new_rgba()
	d = ImageDraw.Draw(layer)
	lane = [(360, 0), (720, 0), (900, H), (180, H)]
	d.polygon(lane, fill=(11, 15, 17, 74))
	d.line(lane + [lane[0]], fill=_hex(accent, 54), width=3)
	for y in range(120, H - 170, 130):
		left, right = _lane_edges(y)
		left2, right2 = _lane_edges(y + 88)
		d.polygon(
			[(left + 28, y), (right - 28, y), (right2 - 38, y + 88), (left2 + 38, y + 88)],
			fill=(28, 32, 34, 44),
			outline=(210, 210, 190, 28),
		)
	for y in range(70, H - 240, 210):
		left, right = _lane_edges(y)
		seg_w = max(5, int((right - left) * 0.025))
		d.line([(W // 2, y), (W // 2 + rng.randint(-18, 18), y + 80)], fill=(226, 206, 145, 70), width=seg_w)
	for _ in range(120):
		y = rng.randint(80, H - 220)
		left, right = _lane_edges(y)
		x = rng.randint(left + 26, right - 26)
		pts = [(x, y)]
		for _i in range(rng.randint(2, 4)):
			px, py = pts[-1]
			pts.append((px + rng.randint(-22, 22), py + rng.randint(14, 42)))
		_poly_line(d, pts, (4, 6, 7, rng.randint(62, 120)), rng.randint(1, 3))
	if kind == "ice":
		for _ in range(34):
			y = rng.randint(120, H - 260)
			left, right = _lane_edges(y)
			x = rng.randint(left + 18, right - 18)
			r = rng.randint(10, 36)
			d.polygon([(x, y - r), (x + r, y), (x, y + r), (x - r, y)], fill=_hex("#CFF8FF", rng.randint(38, 82)))
	elif kind == "water":
		for y in range(280, H - 260, 52):
			left, right = _lane_edges(y)
			d.line([(left + 40, y), (right - 40, y + rng.randint(-10, 10))], fill=_hex(accent, rng.randint(34, 74)), width=2)
	elif kind in {"lava", "core"}:
		for _ in range(12):
			y = rng.randint(170, H - 320)
			left, right = _lane_edges(y)
			x = rng.choice([rng.randint(left, left + 90), rng.randint(right - 90, right)])
			points = [(x, y)]
			for _i in range(3):
				px, py = points[-1]
				points.append((px + rng.randint(-35, 35), py + rng.randint(55, 130)))
			_glow_line(layer, points, accent, rng.randint(3, 7), 10, 170)
	img.alpha_composite(layer)


def _draw_concrete_block(d: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, accent: str, alpha: int = 190) -> None:
	pts = [(x, y), (x + w, y + 10), (x + w - 8, y + h), (x - 10, y + h - 12)]
	d.polygon(pts, fill=(50, 55, 58, alpha), outline=(136, 150, 160, 95))
	d.line([(x + 8, y + h // 2), (x + w - 10, y + h // 2 + 8)], fill=_hex(accent, 74), width=3)
	d.rectangle([x + 18, y + 18, x + min(w - 22, 86), y + 30], fill=(230, 150, 60, 75))


def _draw_tank(d: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, accent: str, vertical: bool = False) -> None:
	fill = (36, 42, 44, 195)
	if vertical:
		d.rounded_rectangle([x, y, x + w, y + h], radius=w // 2, fill=fill, outline=(130, 150, 160, 110), width=3)
		for yy in range(y + 28, y + h - 24, 42):
			d.line([(x + 10, yy), (x + w - 10, yy)], fill=_hex(accent, 80), width=2)
	else:
		d.rounded_rectangle([x, y, x + w, y + h], radius=h // 2, fill=fill, outline=(130, 150, 160, 110), width=3)
		for xx in range(x + 30, x + w - 24, 52):
			d.line([(xx, y + 8), (xx, y + h - 8)], fill=_hex(accent, 80), width=2)


def _draw_pipe(layer: Image.Image, p1: tuple[int, int], p2: tuple[int, int], color: str, width: int = 12) -> None:
	soft = _new_rgba()
	d = ImageDraw.Draw(soft)
	d.line([p1, p2], fill=(0, 0, 0, 120), width=width + 8)
	d.line([p1, p2], fill=(60, 66, 68, 210), width=width)
	d.line([p1, p2], fill=_hex(color, 105), width=max(2, width // 4))
	layer.alpha_composite(soft)


def _draw_side_barricades(img: Image.Image, rng: random.Random, spec: dict) -> None:
	layer = _new_rgba()
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	for side in [-1, 1]:
		for y in range(230, H - 300, 260):
			left, right = _lane_edges(y)
			edge = left if side < 0 else right
			for i in range(3):
				x = edge + side * (42 + i * 78)
				_draw_concrete_block(d, x if side > 0 else x - 110, y + i * 28, 118, 70, accent, 170)
		for _ in range(18):
			y = rng.randint(120, H - 280)
			left, right = _lane_edges(y)
			edge = left if side < 0 else right
			x = edge + side * rng.randint(105, 260)
			r = rng.randint(9, 24)
			d.polygon(
				[(x + rng.randint(-r, r), y + rng.randint(-r, r)) for _i in range(rng.randint(4, 7))],
				fill=(50, 48, 43, rng.randint(70, 132)),
			)
	img.alpha_composite(layer)


def _draw_bottom_gate(img: Image.Image, spec: dict) -> None:
	layer = _new_rgba()
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	y = 1508
	d.polygon([(0, H), (0, y + 185), (230, y + 65), (850, y + 65), (1080, y + 185), (1080, H)], fill=(12, 15, 17, 214))
	d.rectangle([210, y + 76, 870, y + 166], fill=(42, 45, 47, 216))
	d.line([(198, y + 76), (882, y + 76)], fill=_hex(accent, 130), width=4)
	for x in [210, 330, 750, 870]:
		d.rectangle([x - 42, y + 38, x + 42, y + 196], fill=(54, 58, 60, 220), outline=(145, 150, 148, 100), width=2)
		d.rectangle([x - 13, y + 52, x + 13, y + 83], fill=_hex(accent, 165))
	for x in range(270, 820, 92):
		d.polygon([(x, y + 82), (x + 44, y + 82), (x + 16, y + 116), (x - 28, y + 116)], fill=(210, 130, 45, 120))
	img.alpha_composite(layer)


def _draw_lava(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	for side_x in [120, 960]:
		for i in range(4):
			y = 210 + i * 330 + rng.randint(-40, 40)
			_draw_ellipse_glow(layer, (side_x - 80, y - 44, side_x + 80, y + 44), accent, 90, 18)
			_draw_pipe(layer, (side_x, y + 35), (side_x + (-160 if side_x > 540 else 160), y + 160), accent, 14)
	for _ in range(26):
		x = rng.randint(110, 970)
		y = rng.randint(180, 1390)
		pts = [(x, y)]
		for _i in range(rng.randint(3, 5)):
			px, py = pts[-1]
			pts.append((px + rng.randint(-55, 55), py + rng.randint(38, 96)))
		_glow_line(layer, pts, accent, rng.randint(3, 8), 11, 150)
	for _ in range(140):
		x, y = rng.randint(0, W), rng.randint(70, 1540)
		d.ellipse([x, y, x + rng.randint(2, 5), y + rng.randint(2, 5)], fill=_hex("#FFD06A", rng.randint(70, 150)))


def _draw_ice(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	for side in [-1, 1]:
		for y in range(170, 1370, 220):
			left, right = _lane_edges(y)
			edge = left if side < 0 else right
			x = edge + side * rng.randint(80, 190)
			h = rng.randint(130, 260)
			w = rng.randint(48, 110)
			pts = [(x, y - h), (x + side * w, y - 20), (x + side * 35, y + h // 2), (x - side * 42, y + 20)]
			d.polygon(pts, fill=_hex("#CFF8FF", 72), outline=_hex(accent, 130))
	for _ in range(80):
		x, y = rng.randint(0, W), rng.randint(0, H - 260)
		d.line([(x, y), (x + rng.randint(-10, 10), y + rng.randint(18, 42))], fill=(218, 248, 255, rng.randint(45, 95)), width=2)
	for _ in range(18):
		y = rng.randint(180, 1380)
		left, right = _lane_edges(y)
		x = rng.randint(left + 30, right - 30)
		r = rng.randint(18, 54)
		d.polygon([(x, y - r), (x + r, y), (x, y + r), (x - r, y)], fill=_hex("#E7FCFF", 52), outline=_hex(accent, 92))


def _draw_factory(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	secondary = spec["secondary"]
	for side in [-1, 1]:
		x = 95 if side < 0 else 810
		for y in range(180, 1320, 210):
			d.rounded_rectangle([x, y, x + 175, y + 88], radius=8, fill=(24, 30, 32, 185), outline=_hex(accent, 90), width=2)
			for bx in range(x + 18, x + 150, 34):
				d.rectangle([bx, y + 16, bx + 18, y + 72], fill=(72, 76, 72, 125))
	for y in [310, 710, 1110]:
		_draw_pipe(layer, (80, y), (1000, y + rng.randint(-26, 26)), secondary, 7)
	for _ in range(12):
		x, y = rng.randint(80, 900), rng.randint(260, 1260)
		d.rectangle([x, y, x + rng.randint(52, 130), y + rng.randint(38, 86)], fill=(34, 42, 43, 132), outline=_hex(accent, 84), width=2)


def _draw_toxic(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	for side in [-1, 1]:
		for y in [230, 520, 850, 1180]:
			left, right = _lane_edges(y)
			x = (left - 170) if side < 0 else (right + 55)
			_draw_tank(d, x, y, 115, 225, accent, vertical=True)
			_draw_ellipse_glow(layer, (x + 13, y + 38, x + 102, y + 138), accent, 90, 13)
			_draw_pipe(layer, (x + 57, y + 210), (x + 57 + side * -115, y + 275), accent, 10)
	for _ in range(22):
		x, y = rng.randint(90, 990), rng.randint(210, 1390)
		r = rng.randint(16, 52)
		d.ellipse([x - r, y - r // 2, x + r, y + r // 2], fill=_hex(accent, rng.randint(36, 84)))


def _draw_storm(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	secondary = spec["secondary"]
	for x in [145, 935]:
		for y in [280, 690, 1100]:
			d.rectangle([x - 24, y - 95, x + 24, y + 105], fill=(18, 24, 38, 178), outline=(140, 154, 170, 90), width=2)
			for r in [34, 54, 74]:
				d.ellipse([x - r, y - r // 3, x + r, y + r // 3], outline=_hex(secondary, 105), width=3)
			_draw_ellipse_glow(layer, (x - 32, y - 32, x + 32, y + 32), accent, 125, 12)
			if x < 540:
				end = (rng.randint(360, 520), rng.randint(y - 130, y + 130))
			else:
				end = (rng.randint(560, 720), rng.randint(y - 130, y + 130))
			zigzag = [(x, y)]
			for i in range(4):
				px, py = zigzag[-1]
				tx = px + (end[0] - px) / (4 - i)
				ty = py + (end[1] - py) / (4 - i)
				zigzag.append((tx + rng.randint(-36, 36), ty + rng.randint(-34, 34)))
			zigzag.append(end)
			_glow_line(layer, zigzag, rng.choice([accent, secondary, "#5AD6FF"]), 3, 10, 150)


def _draw_water(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	d.rectangle([0, 360, W, 1480], fill=_hex("#0B3946", 60))
	for x in [360, 720]:
		_draw_pipe(layer, (x, 150), (x + rng.randint(-45, 45), 1440), "#D1A15A", 6)
	for y in range(260, 1370, 120):
		left, right = _lane_edges(y)
		d.line([(left - 100, y), (right + 100, y + rng.randint(-12, 12))], fill=(80, 95, 92, 92), width=5)
		d.line([(left - 80, y + 42), (right + 80, y + 42 + rng.randint(-8, 8))], fill=(80, 95, 92, 92), width=5)
	for y in range(420, 1460, 44):
		d.line([(90, y), (990, y + rng.randint(-12, 12))], fill=_hex(accent, rng.randint(24, 62)), width=2)


def _draw_desert(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	secondary = spec["secondary"]
	for y in range(180, 1500, 150):
		d.line([(0, y), (W, y + rng.randint(-60, 70))], fill=_hex(accent, rng.randint(26, 58)), width=rng.randint(3, 7))
	for side in [-1, 1]:
		x = 60 if side < 0 else 780
		for y in [260, 620, 980]:
			_draw_tank(d, x, y, 240, 90, accent)
			_draw_pipe(layer, (x + 120, y + 45), (W // 2 + side * -170, y + 140), secondary, 10)
	for _ in range(110):
		x, y = rng.randint(0, W), rng.randint(100, H - 200)
		d.ellipse([x, y, x + 2, y + 2], fill=_hex("#E8C47A", rng.randint(45, 120)))


def _draw_void(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	secondary = spec["secondary"]
	for side in [-1, 1]:
		for y in [220, 540, 860, 1180]:
			left, right = _lane_edges(y)
			x = left - 210 if side < 0 else right + 210
			d.arc([x - 130, y - 170, x + 130, y + 170], 210 if side < 0 else -30, 330 if side < 0 else 150, fill=(70, 62, 88, 170), width=16)
			d.rectangle([x - 26, y - 15, x + 26, y + 190], fill=(42, 36, 58, 180), outline=_hex(accent, 82), width=2)
	for y in [310, 760, 1210]:
		_draw_ellipse_glow(layer, (390, y - 80, 690, y + 80), secondary, 70, 25)
		d.ellipse([430, y - 42, 650, y + 42], outline=_hex(accent, 120), width=4)
	for _ in range(14):
		x, y = rng.randint(150, 930), rng.randint(190, 1350)
		h = rng.randint(70, 170)
		d.polygon([(x, y - h), (x + 34, y), (x, y + 52), (x - 34, y)], fill=(38, 28, 66, 116), outline=_hex(accent, 86))


def _draw_orbital(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	secondary = spec["secondary"]
	for x in [130, 950]:
		_draw_pipe(layer, (x, 0), (x + rng.randint(-90, 90), H - 120), accent, 18)
		_draw_pipe(layer, (x + (-42 if x > 540 else 42), 0), (x + rng.randint(-110, 110), H - 120), "#6E7D86", 10)
	for y in range(230, 1360, 260):
		d.polygon([(150, y), (320, y + 36), (270, y + 128), (85, y + 84)], fill=(52, 62, 70, 140), outline=_hex(secondary, 82))
		d.polygon([(930, y + 20), (760, y + 54), (815, y + 148), (998, y + 92)], fill=(52, 62, 70, 140), outline=_hex(secondary, 82))
	for _ in range(24):
		x, y = rng.randint(240, 840), rng.randint(170, 1380)
		d.rectangle([x, y, x + 8, y + 8], fill=_hex("#6FEAFF", rng.randint(70, 140)))


def _draw_core(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	secondary = spec["secondary"]
	cx, cy = W // 2, 650
	for r in [390, 295, 205, 120]:
		d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=_hex(accent, max(36, 160 - r // 3)), width=8)
	for angle in range(0, 360, 30):
		a = math.radians(angle)
		p1 = (cx + math.cos(a) * 110, cy + math.sin(a) * 110)
		p2 = (cx + math.cos(a) * 760, cy + math.sin(a) * 760)
		_glow_line(layer, [p1, p2], rng.choice([accent, secondary]), 4, 12, 110)
	_draw_ellipse_glow(layer, (cx - 95, cy - 95, cx + 95, cy + 95), accent, 110, 26)
	for side in [-1, 1]:
		for y in [240, 620, 1000, 1340]:
			x = 90 if side < 0 else 810
			_draw_tank(d, x, y, 190, 78, accent)


THEME_DRAWERS = {
	"lava": _draw_lava,
	"ice": _draw_ice,
	"factory": _draw_factory,
	"toxic": _draw_toxic,
	"storm": _draw_storm,
	"water": _draw_water,
	"desert": _draw_desert,
	"void": _draw_void,
	"orbital": _draw_orbital,
	"core": _draw_core,
}


def _draw_theme(img: Image.Image, rng: random.Random, spec: dict) -> None:
	layer = _new_rgba()
	THEME_DRAWERS[spec["kind"]](layer, rng, spec)
	img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.18)))


def _vignette(img: Image.Image) -> Image.Image:
	mask = Image.new("L", (W, H), 0)
	pixels = mask.load()
	cx, cy = W * 0.5, H * 0.52
	max_dist = math.hypot(cx, cy)
	for y in range(H):
		for x in range(W):
			dist = math.hypot(x - cx, y - cy) / max_dist
			pixels[x, y] = int(max(0.0, (dist - 0.52) / 0.48) ** 1.55 * 106)
	mask = mask.filter(ImageFilter.GaussianBlur(26))
	dark = _new_rgba()
	dark.putalpha(mask)
	return Image.alpha_composite(img, dark)


def _atmosphere(img: Image.Image, rng: random.Random, spec: dict) -> Image.Image:
	layer = _new_rgba()
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	if spec["kind"] in {"ice", "water", "storm"}:
		fog_color = _hex("#BFEFFF", 30)
	elif spec["kind"] in {"lava", "desert", "core"}:
		fog_color = _hex("#FFB35B", 28)
	elif spec["kind"] == "toxic":
		fog_color = _hex("#6BFF82", 26)
	else:
		fog_color = _hex(accent, 25)
	for _ in range(28):
		x = rng.randint(-120, W)
		y = rng.randint(40, H - 230)
		w = rng.randint(180, 520)
		h = rng.randint(22, 90)
		d.ellipse([x, y, x + w, y + h], fill=fog_color)
	layer = layer.filter(ImageFilter.GaussianBlur(22))
	img = Image.alpha_composite(img, layer)
	readability = _new_rgba()
	rd = ImageDraw.Draw(readability)
	rd.polygon([(390, 120), (690, 120), (800, 1430), (280, 1430)], fill=(0, 0, 0, 20))
	img = Image.alpha_composite(img, readability)
	return _vignette(img)


def render_background(spec: dict, seed: int) -> Image.Image:
	rng = random.Random(seed)
	base_path = BG_DIR / spec["base"]
	alt_path = BG_DIR / spec["base_alt"]
	base = _cover(base_path, 0.5, 0.48)
	alt = _cover(alt_path, 0.5, 0.5)
	alt = ImageEnhance.Brightness(alt).enhance(0.75)
	base = Image.blend(base, alt, 0.18)
	img = _grade(base, spec["tint"], spec["accent"])
	_draw_battle_lane(img, rng, spec)
	_draw_side_barricades(img, rng, spec)
	_draw_theme(img, rng, spec)
	_draw_bottom_gate(img, spec)
	img = _atmosphere(img, rng, spec)
	img = ImageEnhance.Contrast(img).enhance(1.08)
	img = ImageEnhance.Color(img).enhance(1.08)
	img = ImageEnhance.Sharpness(img).enhance(1.06)
	return img.convert("RGB")


def make_layout_guide(bg: Image.Image) -> Image.Image:
	guide = bg.convert("RGBA")
	layer = _new_rgba()
	d = ImageDraw.Draw(layer)
	d.rectangle([0, 0, W, 150], outline=(80, 220, 255, 120), width=4)
	d.rectangle([120, 150, 960, 360], outline=(255, 220, 80, 110), width=4)
	d.rectangle([180, 360, 900, 1500], outline=(80, 255, 150, 100), width=4)
	d.rectangle([130, 1430, 950, 1710], outline=(255, 90, 70, 130), width=4)
	d.rectangle([0, 1780, W, H], outline=(170, 150, 255, 120), width=4)
	return Image.alpha_composite(guide, layer).convert("RGB")


def make_contact_sheet(images: list[tuple[dict, Image.Image]]) -> Image.Image:
	thumb_w, thumb_h = 216, 384
	sheet = Image.new("RGB", (thumb_w * 5, thumb_h * 2), (8, 10, 14))
	for i, (_spec, img) in enumerate(images):
		thumb = img.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
		sheet.paste(thumb, ((i % 5) * thumb_w, (i // 5) * thumb_h))
	return sheet


def main() -> int:
	BG_DIR.mkdir(parents=True, exist_ok=True)
	ENV_DIR.mkdir(parents=True, exist_ok=True)
	CONTACT_DIR.mkdir(parents=True, exist_ok=True)
	SOURCE_DIR.mkdir(parents=True, exist_ok=True)
	written: list[str] = []
	images: list[tuple[dict, Image.Image]] = []
	for idx, spec in enumerate(BACKGROUND_SPECS):
		img = render_background(spec, 9100 + idx * 131)
		bg_path = BG_DIR / f"{spec['bg']}.png"
		portrait_path = ENV_DIR / f"{spec['bg']}_portrait.png"
		guide_path = ENV_DIR / f"{spec['bg']}_battle_layout_guide.png"
		img.save(bg_path, optimize=True)
		img.save(portrait_path, optimize=True)
		make_layout_guide(img).save(guide_path, optimize=True)
		written.extend(
			[
				str(bg_path.relative_to(ROOT)),
				str(portrait_path.relative_to(ROOT)),
				str(guide_path.relative_to(ROOT)),
			]
		)
		images.append((spec, img))
	contact_path = CONTACT_DIR / "contact_level_backgrounds_v2.png"
	make_contact_sheet(images).save(contact_path, optimize=True)
	written.append(str(contact_path.relative_to(ROOT)))
	spec_path = SOURCE_DIR / "level_backgrounds_v2_spec.json"
	spec_path.write_text(
		json.dumps(
			{
				"id": "level_backgrounds_v3_concrete",
				"generated_by": "tools/generate_level_backgrounds.py",
				"revision": "v3_concrete_scene_composites",
				"note": "Replaced rejected abstract v2 backgrounds with concrete scene composites. Built-in image generation was attempted, but the output was unrelated and was not used. Final project assets are deterministic Pillow composites from existing production environment material plus theme-specific concrete props.",
				"size": [W, H],
				"mapping_policy": "One env/background per ten campaign levels: 001-010, 011-020, ..., 091-099.",
				"style_constraints": [
					"具象 2.5D 竖版手游战场背景",
					"每张图必须有可识别场景主题和道具",
					"不使用抽象海报式几何图形作为主视觉",
					"上方出生点和中部战斗区保持可读",
					"底部门防区为角色、宠物、技能栏和 HUD 预留空间",
					"无文字、无 UI、无角色、无僵尸",
				],
				"backgrounds": BACKGROUND_SPECS,
				"written": written,
			},
			ensure_ascii=False,
			indent=2,
		)
		+ "\n",
		encoding="utf-8",
	)
	written.append(str(spec_path.relative_to(ROOT)))
	print(f"Generated {len(BACKGROUND_SPECS)} concrete level backgrounds")
	for item in written:
		print(item)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
