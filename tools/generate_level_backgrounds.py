#!/usr/bin/env python3
from __future__ import annotations
import sys
print("OBSOLETE_GUARD: 关卡背景已改用 MiniMax 独立出图并落位, 此染色脚本已停用(会覆盖新图). 如确需运行请手动删除本守卫.", file=sys.stderr)
sys.exit(2)


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
TARGET_W, TARGET_H = 1206, 2622


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
	d.polygon(lane, fill=(8, 12, 14, 24))
	for y in range(120, H - 170, 130):
		left, right = _lane_edges(y)
		left2, right2 = _lane_edges(y + 88)
		d.polygon(
			[(left + 28, y), (right - 28, y), (right2 - 38, y + 88), (left2 + 38, y + 88)],
			fill=(30, 33, 34, 16),
		)
	for y in range(70, H - 240, 210):
		left, right = _lane_edges(y)
		seg_w = max(5, int((right - left) * 0.025))
		d.line([(W // 2, y), (W // 2 + rng.randint(-18, 18), y + 80)], fill=(226, 206, 145, 46), width=seg_w)
	for _ in range(120):
		y = rng.randint(80, H - 220)
		left, right = _lane_edges(y)
		x = rng.randint(left + 26, right - 26)
		pts = [(x, y)]
		for _i in range(rng.randint(2, 4)):
			px, py = pts[-1]
			pts.append((px + rng.randint(-22, 22), py + rng.randint(14, 42)))
		_poly_line(d, pts, (4, 6, 7, rng.randint(22, 62)), rng.randint(1, 2))
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
			_glow_line(layer, points, accent, rng.randint(2, 5), 6, 112)
	img.alpha_composite(layer)


def _draw_concrete_block(d: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, accent: str, alpha: int = 190) -> None:
	pts = [(x, y), (x + w, y + 10), (x + w - 8, y + h), (x - 10, y + h - 12)]
	d.polygon(pts, fill=(50, 55, 58, alpha), outline=(136, 150, 160, 95))
	d.line([(x + 8, y + h // 2), (x + w - 10, y + h // 2 + 8)], fill=_hex(accent, 34), width=2)
	d.rectangle([x + 18, y + 18, x + min(w - 22, 86), y + 30], fill=(230, 150, 60, 42))


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
				_draw_concrete_block(d, x if side > 0 else x - 110, y + i * 28, 118, 70, accent, 112)
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
	d.polygon([(0, H), (0, y + 185), (230, y + 65), (850, y + 65), (1080, y + 185), (1080, H)], fill=(12, 15, 17, 170))
	d.rectangle([210, y + 76, 870, y + 166], fill=(42, 45, 47, 176))
	d.line([(198, y + 76), (882, y + 76)], fill=_hex(accent, 78), width=3)
	for x in [210, 330, 750, 870]:
		d.rectangle([x - 42, y + 38, x + 42, y + 196], fill=(54, 58, 60, 174), outline=(145, 150, 148, 64), width=2)
		d.rectangle([x - 13, y + 52, x + 13, y + 83], fill=_hex(accent, 112))
	for x in range(270, 820, 92):
		d.polygon([(x, y + 82), (x + 44, y + 82), (x + 16, y + 116), (x - 28, y + 116)], fill=(210, 130, 45, 74))
	img.alpha_composite(layer)


def _draw_lava(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	accent = spec["accent"]
	for side_x in [120, 960]:
		for i in range(4):
			y = 210 + i * 330 + rng.randint(-40, 40)
			pts = []
			for a in range(0, 360, 45):
				rx = rng.randint(42, 88)
				ry = rng.randint(22, 54)
				pts.append((side_x + int(math.cos(math.radians(a)) * rx), y + int(math.sin(math.radians(a)) * ry)))
			soft = _new_rgba()
			ImageDraw.Draw(soft).polygon(pts, fill=_hex(accent, 56))
			layer.alpha_composite(soft.filter(ImageFilter.GaussianBlur(14)))
			d.polygon(pts, fill=_hex(accent, 70), outline=_hex("#FFC45E", 75))
			_draw_pipe(layer, (side_x, y + 35), (side_x + (-160 if side_x > 540 else 160), y + 160), accent, 14)
	for _ in range(26):
		x = rng.randint(110, 970)
		y = rng.randint(180, 1390)
		pts = [(x, y)]
		for _i in range(rng.randint(3, 5)):
			px, py = pts[-1]
			pts.append((px + rng.randint(-55, 55), py + rng.randint(38, 96)))
		_glow_line(layer, pts, accent, rng.randint(2, 5), 7, 108)
	for _ in range(140):
		x, y = rng.randint(0, W), rng.randint(70, 1540)
		d.ellipse([x, y, x + rng.randint(2, 4), y + rng.randint(2, 4)], fill=_hex("#FFD06A", rng.randint(40, 100)))


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
		d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=_hex(accent, max(18, 78 - r // 8)), width=5)
	for angle in range(0, 360, 30):
		a = math.radians(angle)
		p1 = (cx + math.cos(a) * 110, cy + math.sin(a) * 110)
		p2 = (cx + math.cos(a) * 760, cy + math.sin(a) * 760)
		_glow_line(layer, [p1, p2], rng.choice([accent, secondary]), 2, 7, 52)
	_draw_ellipse_glow(layer, (cx - 95, cy - 95, cx + 95, cy + 95), accent, 70, 20)
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


def _to_target_fullscreen(img: Image.Image) -> Image.Image:
	"""Convert the design canvas to iPhone 17 full-screen portrait ratio."""
	scale = max(TARGET_W / img.width, TARGET_H / img.height)
	size = (int(img.width * scale + 0.5), int(img.height * scale + 0.5))
	resized = img.resize(size, Image.Resampling.LANCZOS)
	left = max(0, (size[0] - TARGET_W) // 2)
	top = max(0, (size[1] - TARGET_H) // 2)
	return resized.crop((left, top, left + TARGET_W, top + TARGET_H)).convert("RGB")


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


def _soft_spot(layer: Image.Image, x: int, y: int, w: int, h: int, color: str, alpha: int, blur: int) -> None:
	spot = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	d = ImageDraw.Draw(spot)
	d.ellipse([x - w // 2, y - h // 2, x + w // 2, y + h // 2], fill=_hex(color, alpha))
	layer.alpha_composite(spot.filter(ImageFilter.GaussianBlur(blur)))


def _soft_streak(layer: Image.Image, rng: random.Random, color: str, alpha: int, count: int, vertical: bool = True) -> None:
	dust = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	d = ImageDraw.Draw(dust)
	for _i in range(count):
		x = rng.randint(-80, W + 80)
		y = rng.randint(0, H - 180)
		if vertical:
			d.line([(x, y), (x + rng.randint(-18, 18), y + rng.randint(38, 110))], fill=_hex(color, rng.randint(max(8, alpha // 3), alpha)), width=rng.randint(1, 3))
		else:
			d.line([(x, y), (x + rng.randint(160, 420), y + rng.randint(-42, 42))], fill=_hex(color, rng.randint(max(8, alpha // 3), alpha)), width=rng.randint(2, 6))
	layer.alpha_composite(dust.filter(ImageFilter.GaussianBlur(1.1)))


def _soft_particle_field(layer: Image.Image, rng: random.Random, color: str, alpha: int, count: int, size: tuple[int, int]) -> None:
	dots = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	d = ImageDraw.Draw(dots)
	for _i in range(count):
		x = rng.randint(0, W)
		y = rng.randint(0, H - 160)
		r = rng.randint(size[0], size[1])
		d.ellipse([x - r, y - r, x + r, y + r], fill=_hex(color, rng.randint(max(8, alpha // 3), alpha)))
	layer.alpha_composite(dots.filter(ImageFilter.GaussianBlur(0.7)))


def _premium_environment_pass(img: Image.Image, rng: random.Random, spec: dict) -> Image.Image:
	kind = spec["kind"]
	layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	if kind == "lava":
		_soft_spot(layer, 230, 460, 420, 280, "#F37525", 72, 48)
		_soft_spot(layer, 860, 1030, 360, 260, "#F37525", 54, 56)
		_soft_spot(layer, 540, 1480, 620, 220, "#F7A041", 42, 60)
		_soft_streak(layer, rng, "#E97835", 54, 18, vertical=False)
	elif kind == "ice":
		_soft_spot(layer, 220, 430, 500, 360, "#DDF9FF", 58, 44)
		_soft_spot(layer, 890, 820, 470, 330, "#83E6FF", 48, 58)
		_soft_particle_field(layer, rng, "#F1FCFF", 130, 220, (1, 3))
		_soft_streak(layer, rng, "#CFF8FF", 64, 42, vertical=True)
	elif kind == "factory":
		_soft_spot(layer, 210, 650, 420, 250, "#D88937", 42, 48)
		_soft_spot(layer, 860, 360, 360, 220, "#5AD6E8", 34, 46)
		_soft_spot(layer, 850, 1270, 420, 280, "#D88937", 34, 62)
		_soft_particle_field(layer, rng, "#BFC7C8", 52, 140, (1, 2))
	elif kind == "toxic":
		_soft_spot(layer, 185, 520, 430, 260, "#36F26E", 70, 56)
		_soft_spot(layer, 895, 980, 500, 330, "#36F26E", 62, 70)
		_soft_spot(layer, 560, 1370, 520, 260, "#9DFF83", 36, 78)
	elif kind == "storm":
		_soft_spot(layer, 230, 500, 470, 280, "#7B64FF", 46, 58)
		_soft_spot(layer, 820, 820, 540, 300, "#FFE24A", 34, 72)
		_soft_spot(layer, 540, 230, 620, 240, "#5AD6FF", 28, 80)
		_soft_streak(layer, rng, "#BFD9FF", 58, 80, vertical=True)
	elif kind == "water":
		_soft_spot(layer, 540, 820, 860, 620, "#45D6FF", 42, 88)
		_soft_spot(layer, 870, 1320, 420, 280, "#E6B569", 26, 64)
		_soft_streak(layer, rng, "#9AEAFF", 42, 38, vertical=False)
	elif kind == "desert":
		_soft_spot(layer, 540, 650, 960, 760, "#E8A64A", 50, 98)
		_soft_spot(layer, 260, 1280, 520, 260, "#F0C277", 30, 70)
		_soft_streak(layer, rng, "#E8C47A", 58, 48, vertical=False)
	elif kind == "void":
		_soft_spot(layer, 520, 670, 880, 620, "#9C6DFF", 46, 96)
		_soft_spot(layer, 810, 1130, 460, 360, "#FF6BE7", 28, 90)
	elif kind == "orbital":
		_soft_spot(layer, 540, 500, 760, 440, "#C9E6FF", 42, 82)
		_soft_spot(layer, 830, 1170, 420, 280, "#F6A642", 30, 64)
	elif kind == "core":
		_soft_spot(layer, 540, 650, 760, 520, "#F6B63D", 64, 92)
		_soft_spot(layer, 315, 1220, 420, 280, "#72EAFF", 28, 78)
	layer = layer.filter(ImageFilter.GaussianBlur(0.4))
	img = Image.alpha_composite(img, layer)
	shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	d = ImageDraw.Draw(shadow)
	d.rectangle([0, 0, W, 210], fill=(0, 0, 0, 34))
	d.rectangle([0, 1600, W, H], fill=(0, 0, 0, 48))
	d.rectangle([0, 0, 110, H], fill=(0, 0, 0, 44))
	d.rectangle([970, 0, W, H], fill=(0, 0, 0, 44))
	return Image.alpha_composite(img, shadow)


def _mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
	t = max(0.0, min(1.0, t))
	return (
		int(a[0] + (b[0] - a[0]) * t),
		int(a[1] + (b[1] - a[1]) * t),
		int(a[2] + (b[2] - a[2]) * t),
	)


def _color_shift(color: tuple[int, int, int], amount: int) -> tuple[int, int, int]:
	return (
		max(0, min(255, color[0] + amount)),
		max(0, min(255, color[1] + amount)),
		max(0, min(255, color[2] + amount)),
	)


def _gradient_rgba(top: str, bottom: str) -> Image.Image:
	img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
	pixels = img.load()
	ct = _rgb(top)
	cb = _rgb(bottom)
	for y in range(H):
		t = y / max(1, H - 1)
		c = _mix(ct, cb, t)
		for x in range(W):
			pixels[x, y] = (*c, 255)
	return img


def _add_grit(img: Image.Image, seed: int, strength: int = 36) -> Image.Image:
	noise = Image.effect_noise((W, H), 62).convert("L")
	low = noise.point(lambda p: int(max(0, 128 - p) * strength / 128))
	high = noise.point(lambda p: int(max(0, p - 128) * (strength * 0.45) / 127))
	shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	shadow.putalpha(low)
	light = Image.new("RGBA", (W, H), (255, 255, 255, 0))
	light.putalpha(high)
	out = Image.alpha_composite(img, shadow)
	return Image.alpha_composite(out, light)


def _scene_edges(y: float) -> tuple[int, int]:
	t = max(0.0, min(1.0, y / H))
	width = 360 + (780 - 360) * (t ** 0.92)
	center = W * 0.5 + math.sin(t * math.pi * 0.8) * 12
	return int(center - width * 0.5), int(center + width * 0.5)


def _scene_lane_poly(y1: int = 0, y2: int = H) -> list[tuple[int, int]]:
	l1, r1 = _scene_edges(y1)
	l2, r2 = _scene_edges(y2)
	return [(l1, y1), (r1, y1), (r2, y2), (l2, y2)]


def _side_poly(side: int) -> list[tuple[int, int]]:
	top_l, top_r = _scene_edges(0)
	bot_l, bot_r = _scene_edges(H)
	if side < 0:
		return [(0, 0), (top_l + 10, 0), (bot_l - 8, H), (0, H)]
	return [(top_r - 10, 0), (W, 0), (W, H), (bot_r + 8, H)]


def _draw_poly_shadow(layer: Image.Image, pts: list[tuple[int, int]], alpha: int = 115, blur: int = 12, offset: tuple[int, int] = (0, 16)) -> None:
	shadow = _new_rgba()
	shifted = [(x + offset[0], y + offset[1]) for x, y in pts]
	ImageDraw.Draw(shadow).polygon(shifted, fill=(0, 0, 0, alpha))
	layer.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))


def _draw_textured_poly(layer: Image.Image, pts: list[tuple[int, int]], fill: str, outline: str | None = None, alpha: int = 210, outline_alpha: int = 70) -> None:
	_draw_poly_shadow(layer, pts, 75, 10)
	d = ImageDraw.Draw(layer)
	d.polygon(pts, fill=_hex(fill, alpha))
	if outline:
		d.line(pts + [pts[0]], fill=_hex(outline, outline_alpha), width=2)
	mask = Image.new("L", (W, H), 0)
	ImageDraw.Draw(mask).polygon(pts, fill=70)
	noise = Image.effect_noise((W, H), 48).convert("L").filter(ImageFilter.GaussianBlur(0.35))
	dark_alpha = Image.eval(noise, lambda p: int(max(0, 135 - p) * 0.28))
	dark_alpha = Image.composite(dark_alpha, Image.new("L", (W, H), 0), mask)
	dark = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	dark.putalpha(dark_alpha)
	layer.alpha_composite(dark)


def _draw_pavement(layer: Image.Image, rng: random.Random, kind: str, base: str, accent: str) -> None:
	lane = _scene_lane_poly()
	_draw_textured_poly(layer, lane, base, "#AAB6B9", 222, 36)
	d = ImageDraw.Draw(layer)
	for y in range(150, H - 80, 155):
		l1, r1 = _scene_edges(y)
		l2, r2 = _scene_edges(y + 22)
		alpha = 28 if kind not in {"ice", "water"} else 42
		d.line([(l1 + 28, y), (r1 - 28, y + rng.randint(-6, 8))], fill=(0, 0, 0, alpha), width=max(1, int(3 + y / H * 3)))
		if rng.random() < 0.62:
			x = rng.randint(l1 + 80, r1 - 80)
			d.line([(x, y - 42), (x + rng.randint(-18, 22), y + 92)], fill=(255, 255, 255, 12), width=1)
		if kind in {"factory", "core", "orbital"} and y % 310 < 160:
			d.line([(l2 + 50, y + 38), (r2 - 50, y + 46)], fill=_hex(accent, 28), width=3)
	for _ in range(125):
		y = rng.randint(80, H - 150)
		l, r = _scene_edges(y)
		x = rng.randint(l + 20, r - 20)
		pts = [(x, y)]
		for _i in range(rng.randint(2, 5)):
			px, py = pts[-1]
			pts.append((px + rng.randint(-28, 26), py + rng.randint(15, 48)))
		_poly_line(d, pts, (8, 9, 9, rng.randint(18, 58)), rng.randint(1, 2))
	if kind == "ice":
		for _ in range(38):
			y = rng.randint(100, H - 180)
			l, r = _scene_edges(y)
			x = rng.randint(l + 25, r - 25)
			pts = [(x, y)]
			for _i in range(rng.randint(2, 4)):
				px, py = pts[-1]
				pts.append((px + rng.randint(-34, 34), py + rng.randint(22, 64)))
			_poly_line(d, pts, _hex("#DDF9FF", rng.randint(34, 72)), rng.randint(1, 2))
	elif kind == "water":
		for y in range(210, H - 170, 80):
			l, r = _scene_edges(y)
			d.line([(l + 34, y), (r - 34, y + rng.randint(-8, 8))], fill=_hex("#9CEBFF", 28), width=2)
	elif kind == "desert":
		for y in range(130, H - 130, 115):
			l, r = _scene_edges(y)
			d.line([(l + 20, y), (r - 20, y + rng.randint(-16, 16))], fill=_hex("#D7B06D", 34), width=rng.randint(3, 8))


def _draw_big_box(layer: Image.Image, cx: int, y: int, w: int, h: int, color: str, accent: str, side: int = 1, alpha: int = 220) -> None:
	t = y / H
	w = int(w * (0.62 + t * 0.55))
	h = int(h * (0.62 + t * 0.48))
	x1 = cx - w // 2
	x2 = cx + w // 2
	slant = side * int(18 + t * 18)
	top = [(x1 + slant, y), (x2 + slant, y + 12), (x2 - 8, y + h), (x1 - 12, y + h - 14)]
	_draw_textured_poly(layer, top, color, accent, alpha, 72)
	d = ImageDraw.Draw(layer)
	d.line([(x1 + 18, y + h * 0.35), (x2 - 18, y + h * 0.35 + 8)], fill=_hex(accent, 58), width=3)
	d.rectangle([x1 + 20, y + 20, min(x2 - 20, x1 + 86), y + 34], fill=_hex(accent, 54))


def _draw_cylinder(layer: Image.Image, cx: int, y: int, w: int, h: int, color: str, accent: str, alpha: int = 210) -> None:
	t = y / H
	w = int(w * (0.68 + t * 0.45))
	h = int(h * (0.68 + t * 0.45))
	x1, x2 = cx - w // 2, cx + w // 2
	_draw_poly_shadow(layer, [(x1, y), (x2, y), (x2, y + h), (x1, y + h)], 90, 13)
	d = ImageDraw.Draw(layer)
	d.rounded_rectangle([x1, y, x2, y + h], radius=max(8, w // 7), fill=_hex(color, alpha), outline=_hex("#D7E2E7", 52), width=2)
	d.ellipse([x1, y - h * 0.05, x2, y + h * 0.17], fill=_hex(_to_hex(_color_shift(_rgb(color), 22)), alpha), outline=_hex(accent, 72), width=2)
	d.ellipse([x1 + 8, y + h * 0.72, x2 - 8, y + h * 0.92], outline=_hex(accent, 55), width=2)


def _to_hex(color: tuple[int, int, int]) -> str:
	return "#{:02X}{:02X}{:02X}".format(*color)


def _draw_pipe(layer: Image.Image, p1: tuple[int, int], p2: tuple[int, int], color: str, width: int = 12) -> None:
	soft = _new_rgba()
	d = ImageDraw.Draw(soft)
	d.line([p1, p2], fill=(0, 0, 0, 118), width=width + 7)
	d.line([p1, p2], fill=(54, 58, 60, 215), width=width)
	d.line([p1, p2], fill=_hex(color, 78), width=max(2, width // 4))
	layer.alpha_composite(soft.filter(ImageFilter.GaussianBlur(0.55)))


def _draw_irregular_pool(layer: Image.Image, rng: random.Random, cx: int, cy: int, rx: int, ry: int, color: str, alpha: int, edge: str | None = None) -> None:
	pts: list[tuple[int, int]] = []
	for a in range(0, 360, 18):
		r1 = rng.uniform(0.72, 1.16)
		r2 = rng.uniform(0.66, 1.18)
		pts.append((int(cx + math.cos(math.radians(a)) * rx * r1), int(cy + math.sin(math.radians(a)) * ry * r2)))
	soft = _new_rgba()
	sd = ImageDraw.Draw(soft)
	sd.polygon(pts, fill=_hex(color, alpha))
	layer.alpha_composite(soft.filter(ImageFilter.GaussianBlur(max(6, min(rx, ry) // 5))))
	d = ImageDraw.Draw(layer)
	d.polygon(pts, fill=_hex(color, max(16, alpha // 2)))
	if edge:
		d.line(pts + [pts[0]], fill=_hex(edge, min(140, alpha + 35)), width=2)


def _draw_rubble(layer: Image.Image, rng: random.Random, palette: list[str], count: int = 90) -> None:
	d = ImageDraw.Draw(layer)
	for _ in range(count):
		y = rng.randint(60, H - 120)
		l, r = _scene_edges(y)
		side = rng.choice([-1, 1])
		if side < 0:
			x = rng.randint(10, max(20, l - 8))
		else:
			x = rng.randint(min(W - 20, r + 8), W - 10)
		s = rng.randint(4, 18)
		pts = [(x + rng.randint(-s, s), y + rng.randint(-s, s)) for _i in range(rng.randint(4, 7))]
		d.polygon(pts, fill=_hex(rng.choice(palette), rng.randint(70, 145)))


def _draw_depth_haze(layer: Image.Image, color: str, alpha: int = 58) -> None:
	haze = _new_rgba()
	d = ImageDraw.Draw(haze)
	for y in range(0, 520, 8):
		a = int(alpha * (1 - y / 560))
		d.rectangle([0, y, W, y + 8], fill=_hex(color, max(0, a)))
	d.rectangle([0, 0, W, 160], fill=(0, 0, 0, 46))
	layer.alpha_composite(haze.filter(ImageFilter.GaussianBlur(8)))


def _draw_base_gate(layer: Image.Image, accent: str, metal: str = "#34383B") -> None:
	d = ImageDraw.Draw(layer)
	y = 1512
	d.polygon([(0, H), (0, y + 190), (210, y + 76), (870, y + 76), (1080, y + 190), (1080, H)], fill=(8, 10, 12, 145))
	d.rounded_rectangle([196, y + 58, 884, y + 168], radius=6, fill=_hex(metal, 180), outline=(150, 150, 145, 56), width=2)
	for x in [205, 332, 748, 875]:
		d.rounded_rectangle([x - 42, y + 25, x + 42, y + 188], radius=6, fill=(58, 62, 61, 175), outline=(175, 170, 150, 52), width=2)
		d.rectangle([x - 11, y + 42, x + 11, y + 78], fill=_hex(accent, 82))


def _draw_lava_scene(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	for y in [240, 650, 1060, 1370]:
		_draw_irregular_pool(layer, rng, 110, y, 115, 40, "#F37525", 115, "#FFC45E")
		_draw_irregular_pool(layer, rng, 970, y + rng.randint(-30, 30), 130, 45, "#F37525", 100, "#FFC45E")
	for y in [260, 610, 1030]:
		_draw_big_box(layer, 210, y, 230, 95, "#313335", "#F37525", -1)
		_draw_big_box(layer, 860, y + 80, 255, 105, "#2C2F31", "#F37525", 1)
		_draw_pipe(layer, (120, y + 90), (320, y + 185), "#E97835", 17)
		_draw_pipe(layer, (958, y + 165), (760, y + 245), "#E97835", 17)


def _draw_ice_scene(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	for side in [-1, 1]:
		for y in range(120, 1480, 190):
			l, r = _scene_edges(y)
			edge = l if side < 0 else r
			x = edge + side * rng.randint(58, 180)
			h = rng.randint(100, 230)
			w = rng.randint(42, 105)
			pts = [(x, y - h), (x + side * w, y - 20), (x + side * 34, y + h // 2), (x - side * 44, y + 22)]
			d.polygon(pts, fill=_hex("#D9F8FF", rng.randint(66, 112)), outline=_hex("#70D9F4", 86))
	for _ in range(120):
		x, y = rng.randint(0, W), rng.randint(0, H - 260)
		d.line([(x, y), (x + rng.randint(-8, 8), y + rng.randint(16, 42))], fill=(230, 250, 255, rng.randint(35, 78)), width=1)


def _draw_factory_scene(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	for y in [210, 520, 850, 1180]:
		_draw_big_box(layer, 140, y, 210, 120, "#272D2F", "#D88937", -1)
		_draw_big_box(layer, 930, y + 65, 230, 130, "#252B2D", "#D88937", 1)
	for y in [330, 780, 1225]:
		_draw_pipe(layer, (40, y), (1040, y + rng.randint(-26, 26)), "#59666A", 11)
		_draw_pipe(layer, (70, y + 48), (1010, y + 70 + rng.randint(-18, 18)), "#D88937", 7)


def _draw_toxic_scene(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	for y in [220, 540, 890, 1240]:
		_draw_cylinder(layer, 135, y, 112, 230, "#203332", "#36F26E")
		_draw_cylinder(layer, 945, y + 45, 128, 252, "#203332", "#36F26E")
		_draw_irregular_pool(layer, rng, 220, y + 190, 110, 28, "#36F26E", 80, "#9DFF83")
		_draw_irregular_pool(layer, rng, 850, y + 250, 150, 34, "#36F26E", 74, "#9DFF83")
		_draw_pipe(layer, (136, y + 210), (292, y + 300), "#36F26E", 13)
		_draw_pipe(layer, (945, y + 235), (790, y + 330), "#36F26E", 13)


def _draw_storm_scene(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	for x in [120, 960]:
		for y in [260, 690, 1110]:
			_draw_cylinder(layer, x, y, 94, 230, "#1B2530", "#6E80FF", 205)
			for yy in [y + 35, y + 112, y + 190]:
				d.arc([x - 72, yy - 28, x + 72, yy + 28], 0, 360, fill=_hex("#A8B7FF", 82), width=2)
	for _ in range(8):
		x = rng.choice([120, 960])
		y = rng.randint(120, 980)
		pts = [(x, y)]
		for _i in range(4):
			px, py = pts[-1]
			pts.append((px + rng.randint(-68, 68), py + rng.randint(60, 145)))
		_poly_line(d, pts, _hex("#E8F1FF", rng.randint(40, 80)), rng.randint(1, 2))


def _draw_water_scene(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	d.rectangle([0, 360, W, 1460], fill=_hex("#0C3947", 62))
	for y in range(280, 1400, 145):
		l, r = _scene_edges(y)
		d.line([(l - 160, y), (r + 160, y + rng.randint(-8, 8))], fill=(150, 168, 158, 65), width=5)
		d.line([(l - 120, y + 46), (r + 120, y + 42 + rng.randint(-8, 8))], fill=(150, 168, 158, 65), width=5)
	for x in [300, 780]:
		_draw_pipe(layer, (x, 90), (x + rng.randint(-70, 70), 1460), "#C89556", 9)
	for y in range(420, 1480, 60):
		d.line([(80, y), (1000, y + rng.randint(-10, 12))], fill=_hex("#8EEBFF", 30), width=2)


def _draw_desert_scene(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	for y in range(120, 1510, 90):
		d.line([(0, y), (W, y + rng.randint(-45, 55))], fill=_hex("#D6A860", rng.randint(32, 76)), width=rng.randint(4, 10))
	for y in [260, 620, 980, 1320]:
		_draw_cylinder(layer, 120, y, 210, 90, "#463A2C", "#DDA35A", 195)
		_draw_cylinder(layer, 925, y + 55, 230, 96, "#463A2C", "#DDA35A", 195)
		_draw_pipe(layer, (210, y + 44), (400, y + 135), "#A5743C", 16)
		_draw_pipe(layer, (820, y + 100), (670, y + 190), "#A5743C", 16)


def _draw_void_scene(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	d = ImageDraw.Draw(layer)
	for side in [-1, 1]:
		for y in [210, 500, 790, 1080, 1370]:
			l, r = _scene_edges(y)
			x = l - 120 if side < 0 else r + 120
			_draw_big_box(layer, x, y, 120, 260, "#1D1728", "#8E6CBA", side, 210)
	for y in [340, 760, 1180]:
		_draw_irregular_pool(layer, rng, 540, y, 210, 42, "#7D4FFF", 35, None)
	for _ in range(75):
		x, y = rng.randint(0, W), rng.randint(80, 1470)
		d.ellipse([x, y, x + 2, y + 2], fill=_hex("#D4B8FF", rng.randint(20, 58)))


def _draw_orbital_scene(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	for x in [90, 990]:
		_draw_pipe(layer, (x, 0), (x + rng.randint(-95, 95), 1480), "#7B8D96", 22)
		_draw_pipe(layer, (x + (-44 if x > 540 else 44), 0), (x + rng.randint(-115, 115), 1480), "#C9E6FF", 9)
	for y in range(220, 1420, 230):
		_draw_big_box(layer, 170, y, 250, 112, "#303940", "#E0EEF8", -1)
		_draw_big_box(layer, 900, y + 48, 260, 116, "#303940", "#E0EEF8", 1)


def _draw_core_scene(layer: Image.Image, rng: random.Random, spec: dict) -> None:
	for y in [180, 480, 800, 1120, 1400]:
		_draw_big_box(layer, 160, y, 230, 130, "#201C18", "#D89B31", -1, 218)
		_draw_big_box(layer, 920, y + 65, 250, 142, "#201C18", "#D89B31", 1, 218)
		if y in [480, 1120]:
			_draw_irregular_pool(layer, rng, 535, y + 80, 165, 34, "#F0A83C", 54, "#FFE0A0")
	for x in [210, 870]:
		_draw_cylinder(layer, x, 320, 150, 310, "#2A2520", "#F6B63D", 205)


SCENE_DRAWERS = {
	"lava": _draw_lava_scene,
	"ice": _draw_ice_scene,
	"factory": _draw_factory_scene,
	"toxic": _draw_toxic_scene,
	"storm": _draw_storm_scene,
	"water": _draw_water_scene,
	"desert": _draw_desert_scene,
	"void": _draw_void_scene,
	"orbital": _draw_orbital_scene,
	"core": _draw_core_scene,
}


SCENE_PALETTES = {
	"lava": ("#140D0A", "#2B1A13", "#2B2D2F"),
	"ice": ("#071623", "#123247", "#183B4A"),
	"factory": ("#0B1013", "#202628", "#25282A"),
	"toxic": ("#06140E", "#10261B", "#182A27"),
	"storm": ("#070D1A", "#111B2E", "#1B2530"),
	"water": ("#061821", "#0A2A36", "#102E37"),
	"desert": ("#211508", "#473017", "#54412A"),
	"void": ("#070610", "#171021", "#1A1524"),
	"orbital": ("#06101A", "#162430", "#202A31"),
	"core": ("#090705", "#1D1309", "#241F18"),
}


def _render_distinct_scene(spec: dict, seed: int) -> Image.Image:
	rng = random.Random(seed)
	kind = spec["kind"]
	top, bottom, lane_base = SCENE_PALETTES[kind]
	img = _gradient_rgba(top, bottom)
	img = _add_grit(img, seed, 42)
	layer = _new_rgba()
	for side in [-1, 1]:
		_draw_textured_poly(layer, _side_poly(side), _to_hex(_color_shift(_rgb(lane_base), -18)), spec["accent"], 226, 24)
	_draw_pavement(layer, rng, kind, lane_base, spec["accent"])
	SCENE_DRAWERS[kind](layer, rng, spec)
	_draw_rubble(layer, rng, [lane_base, "#31363A", "#4A4238", "#22272B"], 115)
	_draw_base_gate(layer, spec["accent"], _to_hex(_color_shift(_rgb(lane_base), 8)))
	_draw_depth_haze(layer, spec["secondary"], 46)
	img = Image.alpha_composite(img, layer)
	img = _vignette(img)
	img = ImageEnhance.Contrast(img).enhance(1.12)
	img = ImageEnhance.Color(img).enhance(1.09)
	img = ImageEnhance.Sharpness(img).enhance(1.08)
	return _to_target_fullscreen(img)


THEME_SOURCE_MAP = {
	"lava": ("bg_military.png", "bg_biolab.png"),
	"ice": ("bg_city_ruins.png", "bg_subway.png"),
	"factory": ("bg_subway.png", "bg_military.png"),
	"toxic": ("bg_biolab.png", "bg_subway.png"),
	"storm": ("bg_military.png", "bg_subway.png"),
	"water": ("bg_subway.png", "bg_city_ruins.png"),
	"desert": ("bg_military.png", "bg_city_ruins.png"),
	"void": ("bg_main_menu.png", "bg_biolab.png"),
	"orbital": ("bg_military.png", "bg_subway.png"),
	"core": ("bg_biolab.png", "bg_military.png"),
}


THEME_COMPOSITE_STRENGTH = {
	"lava": 0.58,
	"ice": 0.36,
	"factory": 0.66,
	"toxic": 0.76,
	"storm": 0.54,
	"water": 0.78,
	"desert": 0.48,
	"void": 0.62,
	"orbital": 0.58,
	"core": 0.68,
}


def _coverage_mask(kind: str, rng: random.Random, strength: float) -> Image.Image:
	mask = Image.new("L", (W, H), 0)
	d = ImageDraw.Draw(mask)
	for y in range(H):
		top = max(0.0, 1.0 - y / 720)
		bottom = max(0.0, (y - 1280) / 640)
		l, r = _scene_edges(y)
		side_span = max(1, int(190 + 160 * y / H))
		for x in range(W):
			side = 0.0
			if x < l + side_span:
				side = max(side, 1.0 - max(0, x - l) / side_span)
			elif x > r - side_span:
				side = max(side, 1.0 - max(0, r - x) / side_span)
			lane_touch = 0.0
			if kind in {"factory", "toxic", "water", "core"} and l + 85 < x < r - 85:
				lane_touch = 0.18 * max(0.0, 1.0 - abs(x - W * 0.5) / 310)
			a = max(top * 0.82, side * 0.95, bottom * 0.22, lane_touch)
			mask.putpixel((x, y), int(255 * strength * a))
	for _i in range(8):
		y = rng.randint(150, 1320)
		l, r = _scene_edges(y)
		side = rng.choice([-1, 1])
		cx = rng.randint(0, max(20, l + 80)) if side < 0 else rng.randint(min(W - 20, r - 80), W)
		rx = rng.randint(120, 310)
		ry = rng.randint(60, 190)
		d.ellipse([cx - rx, y - ry, cx + rx, y + ry], fill=int(115 * strength))
	return mask.filter(ImageFilter.GaussianBlur(22))


def _soft_color_wash(kind: str, accent: str, secondary: str, rng: random.Random) -> Image.Image:
	layer = _new_rgba()
	d = ImageDraw.Draw(layer)
	wash = {
		"lava": [("#F37525", 50, (190, 480, 450, 260)), ("#F7A041", 35, (840, 980, 390, 280))],
		"ice": [("#CFF8FF", 48, (260, 500, 560, 420)), ("#68D7FF", 32, (820, 900, 430, 330))],
		"factory": [("#D88937", 32, (240, 680, 420, 250)), ("#5AD6E8", 20, (840, 360, 380, 240))],
		"toxic": [("#36F26E", 58, (220, 620, 480, 330)), ("#9DFF83", 38, (850, 1080, 520, 350))],
		"storm": [("#7B64FF", 38, (250, 560, 480, 310)), ("#FFE24A", 28, (820, 900, 420, 300))],
		"water": [("#45D6FF", 44, (540, 860, 900, 640)), ("#E6B569", 18, (850, 1320, 420, 260))],
		"desert": [("#E8A64A", 46, (520, 700, 920, 680)), ("#F0C277", 24, (300, 1280, 520, 260))],
		"void": [("#9C6DFF", 40, (520, 720, 900, 650)), ("#FF6BE7", 22, (810, 1160, 460, 360))],
		"orbital": [("#C9E6FF", 34, (540, 520, 760, 440)), ("#F6A642", 20, (830, 1180, 420, 280))],
		"core": [("#F6B63D", 48, (540, 660, 780, 520)), ("#72EAFF", 24, (320, 1220, 430, 280))],
	}[kind]
	for color, alpha, (cx, cy, ww, hh) in wash:
		_soft_spot(layer, cx, cy, ww, hh, color, alpha, max(48, min(ww, hh) // 4))
	if kind == "ice":
		for _ in range(70):
			x, y = rng.randint(0, W), rng.randint(0, H - 260)
			d.line([(x, y), (x + rng.randint(-7, 7), y + rng.randint(16, 38))], fill=(235, 252, 255, rng.randint(22, 58)), width=1)
	elif kind == "water":
		for y in range(430, 1450, 68):
			d.line([(80, y), (1000, y + rng.randint(-10, 10))], fill=_hex("#9AEAFF", rng.randint(18, 44)), width=2)
	elif kind == "desert":
		for _ in range(30):
			y = rng.randint(140, 1460)
			d.line([(rng.randint(-120, 100), y), (rng.randint(840, W + 150), y + rng.randint(-50, 54))], fill=_hex("#E8C47A", rng.randint(22, 48)), width=rng.randint(2, 5))
	return layer.filter(ImageFilter.GaussianBlur(0.45))


def _natural_landmark_mask(rng: random.Random, side: int, y: int, w: int, h: int) -> Image.Image:
	mask = Image.new("L", (W, H), 0)
	d = ImageDraw.Draw(mask)
	x = rng.randint(-80, 80) if side < 0 else rng.randint(W - 80, W + 80)
	pts: list[tuple[int, int]] = []
	for a in range(0, 360, 22):
		rx = w * rng.uniform(0.55, 1.08)
		ry = h * rng.uniform(0.52, 1.05)
		pts.append((int(x + math.cos(math.radians(a)) * rx), int(y + math.sin(math.radians(a)) * ry)))
	d.polygon(pts, fill=rng.randint(70, 120))
	return mask.filter(ImageFilter.GaussianBlur(rng.randint(18, 34)))


def _composite_source_variation(base: Image.Image, source: Image.Image, rng: random.Random, kind: str, strength: float) -> Image.Image:
	mask = _coverage_mask(kind, rng, strength)
	out = Image.composite(source, base, mask)
	secondary = source.filter(ImageFilter.GaussianBlur(1.4))
	for i in range(5):
		side = -1 if i % 2 == 0 else 1
		patch_mask = _natural_landmark_mask(
			rng,
			side,
			rng.randint(230, 1360),
			rng.randint(95, 210),
			rng.randint(120, 300),
		)
		out = Image.composite(secondary, out, patch_mask)
	return out


def _render_premium_collage_scene(spec: dict, seed: int) -> Image.Image:
	rng = random.Random(seed)
	kind = spec["kind"]
	base = _cover(BG_DIR / "bg_city_ruins.png", 0.5, 0.48)
	primary_name, secondary_name = THEME_SOURCE_MAP[kind]
	primary_path = BG_DIR / primary_name
	secondary_path = BG_DIR / secondary_name
	source = _cover(primary_path if primary_path.exists() else BG_DIR / "bg_city_ruins.png", 0.5, 0.52)
	if secondary_path.exists():
		secondary = _cover(secondary_path, 0.5, 0.50).filter(ImageFilter.GaussianBlur(1.2))
		source = Image.blend(source, secondary, 0.24)
	source = ImageEnhance.Contrast(source).enhance(1.08)
	source = ImageEnhance.Color(source).enhance(1.06)
	composited = _composite_source_variation(base, source, rng, kind, THEME_COMPOSITE_STRENGTH[kind])
	composited = _grade(composited, spec["tint"], spec["accent"], contrast=1.08, color=1.04, brightness=0.93)
	composited = Image.alpha_composite(composited, _soft_color_wash(kind, spec["accent"], spec["secondary"], rng))
	soft_vignette = _vignette(composited)
	soft_vignette = ImageEnhance.Contrast(soft_vignette).enhance(1.09)
	soft_vignette = ImageEnhance.Color(soft_vignette).enhance(1.08)
	soft_vignette = ImageEnhance.Sharpness(soft_vignette).enhance(1.07)
	return _to_target_fullscreen(soft_vignette)


def render_background(spec: dict, seed: int) -> Image.Image:
	return _render_premium_collage_scene(spec, seed)


def make_layout_guide(bg: Image.Image) -> Image.Image:
	guide = bg.convert("RGBA")
	tw, th = guide.size
	layer = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
	d = ImageDraw.Draw(layer)
	sx = tw / W
	sy = th / H
	def box(x1: float, y1: float, x2: float, y2: float) -> list[int]:
		return [int(x1 * sx), int(y1 * sy), int(x2 * sx), int(y2 * sy)]
	d.rectangle(box(0, 0, W, 150), outline=(80, 220, 255, 120), width=4)
	d.rectangle(box(120, 150, 960, 360), outline=(255, 220, 80, 110), width=4)
	d.rectangle(box(180, 360, 900, 1500), outline=(80, 255, 150, 100), width=4)
	d.rectangle(box(130, 1430, 950, 1710), outline=(255, 90, 70, 130), width=4)
	d.rectangle(box(0, 1780, W, H), outline=(170, 150, 255, 120), width=4)
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
				"id": "level_backgrounds_v3_iphone17_concrete",
				"generated_by": "tools/generate_level_backgrounds.py",
				"revision": "v3_iphone17_fullscreen_concrete_scene_composites",
				"note": "Replaced rejected abstract v2 backgrounds with concrete scene composites at iPhone 17 full-screen portrait ratio. Built-in image generation was attempted, but the output was unrelated and was not used. Final project assets are deterministic Pillow composites from existing production environment material plus theme-specific concrete props.",
				"size": [TARGET_W, TARGET_H],
				"design_canvas": [W, H],
				"target_device_basis": "iPhone 17 portrait full-screen 1206x2622 px; same family ratio as iPhone 17 Pro Max 1320x2868.",
				"mapping_policy": "One env/background per ten campaign levels: 001-010, 011-020, ..., 091-099.",
				"style_constraints": [
					"按 iPhone 17 竖屏全屏比例输出 1206x2622",
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
	print(f"Generated {len(BACKGROUND_SPECS)} iPhone 17 concrete level backgrounds")
	for item in written:
		print(item)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
