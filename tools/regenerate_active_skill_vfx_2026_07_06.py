#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import math
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
VFX_DIR = PROD / "sprites" / "vfx"
SEQ_DIR = PROD / "sprites" / "vfx_sequences"
SOURCE_DIR = PROD / "source_refs" / "generated" / "active_skill_vfx_review_2026_07_06"
CONTACT_DIR = PROD / "contact_sheets"
INDEX_PATH = PROD / "OUTSOURCER_ASSET_INDEX.json"
STAMP = "2026_07_06"

DEFAULT_SOURCE = Path(
	"/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/"
	"ig_0ce8b4c6ddc21b7f016a4b629db29481938670c0680e93ffcb.png"
)

VFX_ROWS = {
	"vfx_hit_fire": {"row": 0, "frames": 12, "size": 512, "fps": 22, "fit": 0.76, "single": "vfx_hit_fire.png"},
	"vfx_explosion_fire": {"row": 1, "frames": 16, "size": 512, "fps": 20, "fit": 0.92, "single": "vfx_explosion_fire.png"},
	"vfx_active_sig_vanguard_railvolley": {"row": 2, "frames": 14, "size": 768, "fps": 20, "fit": 0.88},
	"vfx_active_sig_vanguard_overload": {"row": 3, "frames": 14, "size": 768, "fps": 20, "fit": 0.86},
	"vfx_active_sig_blaze_meltdown": {"row": 1, "frames": 14, "size": 768, "fps": 20, "fit": 0.9},
	"vfx_active_sig_frost_glacier": {"row": 4, "frames": 14, "size": 768, "fps": 20, "fit": 0.9},
	"vfx_active_sig_volt_storm": {"row": 5, "frames": 14, "size": 768, "fps": 20, "fit": 0.93},
}

SOURCE_PROMPT = (
	"High-end 2.5D mobile game VFX reference sheet for a post-apocalyptic tower-defense shooter, "
	"pure black background for alpha extraction, no text, no UI, no border. Six rows: centered fire hit, "
	"molten fire active explosion, artillery rail volley impact, armored overload surge, natural frost glacier, "
	"and volt storm lightning vortex. AAA App Store quality rendered sprite effects, no vector rings, "
	"soft alpha-friendly falloff."
)


def _sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def _smoothstep(edge0: float, edge1: float, x: np.ndarray) -> np.ndarray:
	t = np.clip((x - edge0) / max(edge1 - edge0, 0.001), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


def black_to_alpha(src: Image.Image) -> Image.Image:
	arr = np.asarray(src.convert("RGB"), dtype=np.float32)
	brightness = arr.max(axis=2)
	saturation = arr.max(axis=2) - arr.min(axis=2)
	alpha = _smoothstep(26.0, 110.0, brightness) * 255.0
	chroma_alpha = _smoothstep(24.0, 112.0, saturation) * _smoothstep(22.0, 74.0, brightness) * 220.0
	alpha = np.maximum(alpha, chroma_alpha)
	# The model reference sheet is JPEG-like on black; strip low-value compression haze
	# so it cannot upscale into rectangular cutout blocks.
	alpha = np.where((brightness < 24.0) | ((brightness < 34.0) & (saturation < 18.0)), 0.0, alpha)
	rgb = np.clip(arr * 1.08 + 2.0, 0, 255).astype(np.uint8)
	out = np.dstack([rgb, np.clip(alpha, 0, 255).astype(np.uint8)])
	img = Image.fromarray(out)
	a = img.getchannel("A").filter(ImageFilter.GaussianBlur(0.45))
	img.putalpha(_clean_low_alpha(a, 26))
	return img


def _clean_low_alpha(alpha: Image.Image, floor: int) -> Image.Image:
	def remap(value: int) -> int:
		if value < floor:
			return 0
		t = (value - floor) / max(1, 255 - floor)
		return int(255 * (t ** 0.82))
	return alpha.point(remap)


def alpha_bbox(img: Image.Image, threshold: int = 4) -> tuple[int, int, int, int]:
	alpha = img.getchannel("A").point(lambda v: 255 if v > threshold else 0)
	bbox = alpha.getbbox()
	if bbox is None:
		return (0, 0, img.width, img.height)
	return bbox


def pad_bbox(bbox: tuple[int, int, int, int], size: tuple[int, int], pad_ratio: float) -> tuple[int, int, int, int]:
	x0, y0, x1, y1 = bbox
	w, h = size
	pad_x = int(max(8, (x1 - x0) * pad_ratio))
	pad_y = int(max(8, (y1 - y0) * pad_ratio))
	return (
		max(0, x0 - pad_x),
		max(0, y0 - pad_y),
		min(w, x1 + pad_x),
		min(h, y1 + pad_y),
	)


def center_on_canvas(img: Image.Image, target: int, fit: float) -> Image.Image:
	bbox = pad_bbox(alpha_bbox(img), img.size, 0.18)
	content = img.crop(bbox)
	scale = min(target * fit / max(content.width, 1), target * fit / max(content.height, 1))
	new_size = (max(1, int(round(content.width * scale))), max(1, int(round(content.height * scale))))
	content = content.resize(new_size, Image.Resampling.LANCZOS)
	content = ImageEnhance.Sharpness(content).enhance(1.22)
	content = ImageEnhance.Contrast(content).enhance(1.08)
	canvas = Image.new("RGBA", (target, target), (0, 0, 0, 0))
	x = (target - content.width) // 2
	y = (target - content.height) // 2
	canvas.alpha_composite(content, (x, y))
	canvas.putalpha(_clean_low_alpha(canvas.getchannel("A"), 22))
	return canvas


def crop_grid_frames(sheet: Image.Image, row: int) -> list[Image.Image]:
	w, h = sheet.size
	cell_w = w / 8.0
	cell_h = h / 6.0
	out: list[Image.Image] = []
	for col in range(8):
		x0 = int(round(col * cell_w))
		x1 = int(round((col + 1) * cell_w))
		y0 = int(round(row * cell_h))
		y1 = int(round((row + 1) * cell_h))
		# The AI reference sheet lets smoke and sparks bleed across cells. A conservative
		# inset keeps adjacent-frame haze from becoming rectangular alpha artifacts.
		inset_x = max(0, int(round(cell_w * 0.075)))
		inset_y = max(0, int(round(cell_h * 0.035)))
		out.append(sheet.crop((x0 + inset_x, y0 + inset_y, x1 - inset_x, y1 - inset_y)))
	return out


def resample_frames(frames: list[Image.Image], target_count: int) -> list[Image.Image]:
	if target_count == len(frames):
		return frames
	out: list[Image.Image] = []
	for idx in range(target_count):
		pos = idx * (len(frames) - 1) / max(target_count - 1, 1)
		lo = int(math.floor(pos))
		hi = min(len(frames) - 1, lo + 1)
		t = pos - lo
		if hi == lo or t <= 0.001:
			out.append(frames[lo].copy())
		else:
			out.append(Image.blend(frames[lo], frames[hi], t))
	return out


def add_soft_render_polish(img: Image.Image, sequence_id: str, frame_index: int, frame_count: int) -> Image.Image:
	out = img.copy()
	alpha = out.getchannel("A")
	glow_color = (255, 118, 28) if "fire" in sequence_id or "blaze" in sequence_id or "overload" in sequence_id else (120, 230, 255)
	if "railvolley" in sequence_id:
		glow_color = (255, 208, 92)
	elif "volt" in sequence_id:
		glow_color = (120, 205, 255)
	glow_alpha = alpha.filter(ImageFilter.GaussianBlur(out.width * 0.032)).point(lambda v: int(v * 0.52))
	glow = Image.new("RGBA", out.size, (*glow_color, 0))
	glow.putalpha(glow_alpha)
	out = Image.alpha_composite(glow, out)

	# Add tiny high-frequency embers/arcs so upscaled model frames do not look soft.
	draw = ImageDraw.Draw(out, "RGBA")
	rng = np.random.default_rng(abs(hash((sequence_id, frame_index, STAMP))) % (2**32))
	pulse = math.sin((frame_index + 1) / max(frame_count, 1) * math.pi)
	if "fire" in sequence_id or "blaze" in sequence_id or "railvolley" in sequence_id or "overload" in sequence_id:
		amount = 34 if "hit" in sequence_id else 58
		for _ in range(amount):
			r = rng.uniform(12, out.width * (0.34 if "hit" in sequence_id else 0.42)) * (0.65 + pulse * 0.5)
			a = rng.uniform(-math.pi, math.pi)
			cx = out.width / 2 + math.cos(a) * r * rng.uniform(0.2, 1.0)
			cy = out.height / 2 + math.sin(a) * r * rng.uniform(0.16, 0.78)
			size = rng.uniform(1.1, 3.8) * (0.7 + pulse)
			draw.ellipse((cx - size, cy - size, cx + size, cy + size), fill=(255, rng.integers(128, 222), rng.integers(30, 98), rng.integers(40, 170)))
	elif "volt" in sequence_id:
		for _ in range(24):
			cx = rng.uniform(out.width * 0.22, out.width * 0.78)
			cy = rng.uniform(out.height * 0.28, out.height * 0.72)
			size = rng.uniform(1.0, 3.2) * (0.8 + pulse)
			draw.ellipse((cx - size, cy - size, cx + size, cy + size), fill=(155, 226, 255, int(34 + 105 * pulse)))
	elif "frost" in sequence_id:
		for _ in range(22):
			cx = rng.uniform(out.width * 0.24, out.width * 0.76)
			cy = rng.uniform(out.height * 0.42, out.height * 0.68)
			size = rng.uniform(9, 28) * (0.7 + pulse)
			draw.polygon(
				[(cx, cy - size), (cx + size * 0.22, cy + size * 0.6), (cx - size * 0.2, cy + size * 0.48)],
				fill=(180, 235, 255, int(24 + 66 * pulse)),
				outline=(232, 252, 255, int(38 + 80 * pulse)),
			)
	a = _clean_low_alpha(out.getchannel("A").filter(ImageFilter.GaussianBlur(0.2)), 18)
	out.putalpha(ImageChops.multiply(a, _edge_fade_mask(out.size, max(12, out.width // 32))))
	return out


def radial_layer(size: tuple[int, int], center: tuple[float, float], color: tuple[int, int, int, int], radius: float, power: float = 2.0) -> Image.Image:
	w, h = size
	yy, xx = np.mgrid[0:h, 0:w]
	dx = (xx - center[0]) / max(radius, 1.0)
	dy = (yy - center[1]) / max(radius, 1.0)
	dist = np.sqrt(dx * dx + dy * dy)
	alpha = np.clip((1.0 - dist), 0.0, 1.0) ** power * color[3]
	arr = np.zeros((h, w, 4), dtype=np.uint8)
	arr[..., 0] = color[0]
	arr[..., 1] = color[1]
	arr[..., 2] = color[2]
	arr[..., 3] = np.clip(alpha, 0, 255).astype(np.uint8)
	return Image.fromarray(arr)


def make_frost_custom_frames(frame_count: int, size: int) -> list[Image.Image]:
	frames: list[Image.Image] = []
	rng = np.random.default_rng(2026070617)
	crystals = []
	for _ in range(34):
		crystals.append(
			(
				float(rng.uniform(size * 0.25, size * 0.75)),
				float(rng.uniform(size * 0.49, size * 0.67)),
				float(rng.uniform(size * 0.06, size * 0.18)),
				float(rng.uniform(size * 0.018, size * 0.05)),
				float(rng.uniform(-0.34, 0.34)),
				float(rng.uniform(0.55, 1.15)),
			)
		)
	for idx in range(frame_count):
		p = idx / max(frame_count - 1, 1)
		grow = min(1.0, p / 0.38)
		fade = 1.0 if p < 0.68 else max(0.0, 1.0 - (p - 0.68) / 0.32)
		pulse = math.sin(math.pi * min(p, 0.86))
		img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
		glow = radial_layer((size, size), (size * 0.5, size * 0.58), (115, 226, 255, int(110 * pulse * fade)), size * (0.32 + 0.16 * grow), 1.65)
		img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(size * 0.018)))
		shard_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
		draw = ImageDraw.Draw(shard_layer, "RGBA")
		for x, y, height, width, lean, offset in crystals:
			local = np.clip((grow * 1.22 - (offset - 0.55) * 0.34), 0.0, 1.0)
			if local <= 0.02:
				continue
			hh = height * local
			ww = width * (0.65 + 0.35 * local)
			tip = (x + lean * hh, y - hh)
			left = (x - ww, y + hh * 0.1)
			right = (x + ww, y + hh * 0.08)
			a = int((68 + 118 * local) * fade)
			draw.polygon([left, tip, right], fill=(116, 205, 244, a), outline=(226, 250, 255, min(220, a + 48)))
			draw.line((x, y, tip[0], tip[1]), fill=(250, 255, 255, min(210, a + 56)), width=max(1, int(size * 0.004)))
		img.alpha_composite(shard_layer.filter(ImageFilter.GaussianBlur(size * 0.002)))
		mist = Image.new("RGBA", (size, size), (0, 0, 0, 0))
		md = ImageDraw.Draw(mist, "RGBA")
		local_rng = np.random.default_rng(2026070629 + idx)
		for _ in range(120):
			x = float(local_rng.normal(size * 0.5, size * (0.16 + 0.08 * grow)))
			y = float(local_rng.normal(size * 0.6, size * 0.07))
			r = float(local_rng.uniform(size * 0.004, size * 0.017)) * (0.8 + grow)
			a = int(local_rng.uniform(12, 64) * fade * (0.55 + pulse))
			md.ellipse((x - r, y - r, x + r, y + r), fill=(190, 238, 255, a))
		img.alpha_composite(mist.filter(ImageFilter.GaussianBlur(size * 0.008)))
		img = add_soft_render_polish(img, "vfx_active_sig_frost_glacier", idx, frame_count)
		frames.append(img)
	return frames


def _jagged_path(start: np.ndarray, end: np.ndarray, rng: np.random.Generator, steps: int, jitter: float) -> list[tuple[float, float]]:
	dir_vec = end - start
	length = float(np.linalg.norm(dir_vec))
	if length < 1.0:
		return [(float(start[0]), float(start[1])), (float(end[0]), float(end[1]))]
	norm = np.array([-dir_vec[1], dir_vec[0]]) / length
	points = []
	for i in range(steps + 1):
		t = i / steps
		offset = rng.normal(0.0, jitter) * math.sin(math.pi * t)
		pt = start + dir_vec * t + norm * offset
		points.append((float(pt[0]), float(pt[1])))
	return points


def make_volt_custom_frames(frame_count: int, size: int) -> list[Image.Image]:
	frames: list[Image.Image] = []
	for idx in range(frame_count):
		p = idx / max(frame_count - 1, 1)
		grow = min(1.0, p / 0.26)
		fade = 1.0 if p < 0.7 else max(0.0, 1.0 - (p - 0.7) / 0.3)
		pulse = math.sin(math.pi * min(p, 0.9))
		rng = np.random.default_rng(2026070641 + idx * 17)
		img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
		core = radial_layer((size, size), (size * 0.5, size * 0.5), (130, 230, 255, int(210 * fade)), size * (0.08 + 0.04 * pulse), 1.3)
		img.alpha_composite(core)
		arc_glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
		ad = ImageDraw.Draw(arc_glow, "RGBA")
		center = np.array([size * 0.5, size * 0.5])
		for i in range(15):
			angle = -math.pi / 2 + (i - 7) * 0.25 + rng.normal(0.0, 0.18)
			length = size * rng.uniform(0.18, 0.46) * (0.45 + 0.72 * grow)
			end = center + np.array([math.cos(angle), math.sin(angle)]) * length
			path = _jagged_path(center + rng.normal(0, size * 0.012, 2), end, rng, 7, size * 0.035)
			alpha = int(rng.uniform(72, 170) * fade * (0.55 + pulse))
			width = max(2, int(size * rng.uniform(0.004, 0.009)))
			ad.line(path, fill=(126, 218, 255, alpha), width=width)
			if i % 3 == 0:
				ad.line(path, fill=(255, 184, 74, int(alpha * 0.48)), width=max(1, width - 1))
			if len(path) > 3 and rng.random() < 0.65:
				branch_start = np.array(path[rng.integers(2, len(path) - 1)])
				branch_end = branch_start + np.array([math.cos(angle + rng.uniform(-0.9, 0.9)), math.sin(angle + rng.uniform(-0.9, 0.9))]) * length * rng.uniform(0.18, 0.34)
				ad.line(_jagged_path(branch_start, branch_end, rng, 4, size * 0.025), fill=(182, 240, 255, int(alpha * 0.55)), width=max(1, width - 1))
		img.alpha_composite(arc_glow.filter(ImageFilter.GaussianBlur(size * 0.007)))
		img.alpha_composite(arc_glow)
		particles = Image.new("RGBA", (size, size), (0, 0, 0, 0))
		pd = ImageDraw.Draw(particles, "RGBA")
		for _ in range(90):
			r = rng.uniform(size * 0.04, size * 0.34) * (0.5 + grow)
			a = rng.uniform(-math.pi, math.pi)
			x = size * 0.5 + math.cos(a) * r
			y = size * 0.5 + math.sin(a) * r
			s = rng.uniform(size * 0.002, size * 0.008)
			pd.ellipse((x - s, y - s, x + s, y + s), fill=(154, 228, 255, int(rng.uniform(20, 120) * fade)))
		img.alpha_composite(particles.filter(ImageFilter.GaussianBlur(size * 0.002)))
		img = add_soft_render_polish(img, "vfx_active_sig_volt_storm", idx, frame_count)
		frames.append(img)
	return frames


def _edge_fade_mask(size: tuple[int, int], margin: int) -> Image.Image:
	w, h = size
	mask = Image.new("L", size, 255)
	pix = mask.load()
	for y in range(h):
		for x in range(w):
			dist = min(x, y, w - 1 - x, h - 1 - y)
			if dist < margin:
				t = dist / max(1, margin)
				pix[x, y] = int(255 * t * t * (3.0 - 2.0 * t))
	return mask


def write_sequence(sequence_id: str, source_frames: list[Image.Image], config: dict, source_ref: str) -> list[str]:
	target = int(config["size"])
	if sequence_id == "vfx_active_sig_frost_glacier":
		frames = make_frost_custom_frames(int(config["frames"]), target)
	elif sequence_id == "vfx_active_sig_volt_storm":
		frames = make_volt_custom_frames(int(config["frames"]), target)
	else:
		base_frames = [center_on_canvas(black_to_alpha(frame), target, float(config["fit"])) for frame in source_frames]
		frames = resample_frames(base_frames, int(config["frames"]))
	out_dir = SEQ_DIR / sequence_id
	out_dir.mkdir(parents=True, exist_ok=True)
	written: list[str] = []
	rel_frames: list[str] = []
	for idx, frame in enumerate(frames, start=1):
		frame = add_soft_render_polish(frame, sequence_id, idx - 1, len(frames))
		out_path = out_dir / f"{sequence_id}_{idx:02d}.png"
		frame.save(out_path)
		written.append(str(out_path.relative_to(ROOT)))
		rel_frames.append(str(out_path.relative_to(PROD)))
	sequence = {
		"id": sequence_id,
		"fps": int(config["fps"]),
		"frames": rel_frames,
		"source": source_ref,
		"integration": "AI-rendered reference sheet extraction plus local alpha cleanup; PNG bitmap sequence, no SVG/vector primitives",
	}
	(out_dir / f"{sequence_id}_sequence.json").write_text(json.dumps(sequence, indent=2) + "\n")
	written.append(str((out_dir / f"{sequence_id}_sequence.json").relative_to(ROOT)))
	if config.get("single"):
		peak_index = min(len(frames) - 1, max(0, int(round(len(frames) * 0.46))))
		single_path = VFX_DIR / str(config["single"])
		add_soft_render_polish(frames[peak_index], sequence_id, peak_index, len(frames)).save(single_path)
		written.append(str(single_path.relative_to(ROOT)))
	return written


def make_contact_sheet(sequence_ids: list[str], out_path: Path, title: str) -> str:
	cell_w, cell_h = 176, 156
	header = 48
	cols = 8
	rows = len(sequence_ids)
	sheet = Image.new("RGBA", (cols * cell_w, header + rows * cell_h), (7, 10, 14, 255))
	draw = ImageDraw.Draw(sheet, "RGBA")
	draw.text((18, 16), title, fill=(232, 240, 246, 255))
	for row, seq_id in enumerate(sequence_ids):
		seq_dir = SEQ_DIR / seq_id
		frames = sorted(seq_dir.glob(f"{seq_id}_*.png"))
		if len(frames) > cols:
			idxs = [round(i * (len(frames) - 1) / (cols - 1)) for i in range(cols)]
			frames = [frames[i] for i in idxs]
		for col, frame_path in enumerate(frames[:cols]):
			x = col * cell_w
			y = header + row * cell_h
			draw.rectangle((x, y, x + cell_w, y + cell_h), fill=(10, 14, 20, 255))
			img = Image.open(frame_path).convert("RGBA")
			img.thumbnail((138, 116), Image.Resampling.LANCZOS)
			sheet.alpha_composite(img, (x + (cell_w - img.width) // 2, y + 12))
		draw.text((8, header + row * cell_h + cell_h - 22), seq_id.replace("vfx_active_sig_", "active_")[:32], fill=(210, 225, 235, 230))
	out_path.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(out_path)
	return str(out_path.relative_to(ROOT))


def update_index(manifest_path: Path, contact_paths: list[str], reference_path: Path) -> None:
	data = json.loads(INDEX_PATH.read_text())
	items = data.setdefault("items", [])
	entry_id = "active_skill_fire_vfx_review_2026_07_06"
	entry = {
		"id": entry_id,
		"category": "vfx_polish",
		"status": "accepted_runtime_pending",
		"description": "Owner-requested review and replacement of fire hit/explosion and all character active skill VFX to remove side-plume fire, hard cutout edges, and geometric/vector-looking active skill frames.",
		"source": str(manifest_path.relative_to(ROOT)),
		"reference": str(reference_path.relative_to(ROOT)),
		"derived": contact_paths,
	}
	for idx, item in enumerate(items):
		if isinstance(item, dict) and item.get("id") == entry_id:
			items[idx] = entry
			break
	else:
		items.append(entry)
	INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("--source", default=str(DEFAULT_SOURCE), help="AI-rendered reference sheet")
	args = parser.parse_args()
	source = Path(args.source).expanduser()
	if not source.exists():
		raise FileNotFoundError(source)

	SOURCE_DIR.mkdir(parents=True, exist_ok=True)
	reference_path = SOURCE_DIR / f"top_tier_active_skill_vfx_reference_{STAMP}.png"
	shutil.copy2(source, reference_path)

	sheet = Image.open(source).convert("RGB")
	written: list[str] = [str(reference_path.relative_to(ROOT))]
	row_cache: dict[int, list[Image.Image]] = {}
	for row in range(6):
		row_cache[row] = crop_grid_frames(sheet, row)

	for sequence_id, config in VFX_ROWS.items():
		written += write_sequence(sequence_id, row_cache[int(config["row"])], config, str(reference_path.relative_to(ROOT)))

	fire_sheet = make_contact_sheet(
		["vfx_hit_fire", "vfx_explosion_fire", "vfx_active_sig_blaze_meltdown"],
		CONTACT_DIR / f"contact_fire_vfx_review_{STAMP}.png",
		"Fire VFX review replacement: centered, feathered, no side plume",
	)
	active_sheet = make_contact_sheet(
		[
			"vfx_active_sig_vanguard_railvolley",
			"vfx_active_sig_vanguard_overload",
			"vfx_active_sig_blaze_meltdown",
			"vfx_active_sig_frost_glacier",
			"vfx_active_sig_volt_storm",
		],
		CONTACT_DIR / f"contact_active_skill_vfx_review_{STAMP}.png",
		"Active skill VFX review replacement: rendered bitmap sequences",
	)
	written += [fire_sheet, active_sheet]

	manifest_path = SOURCE_DIR / f"active_skill_vfx_manifest_{STAMP}.json"
	manifest = {
		"id": "active_skill_fire_vfx_review_2026_07_06",
		"source_prompt": SOURCE_PROMPT,
		"source_image_original": str(source),
		"source_image_project": str(reference_path.relative_to(ROOT)),
		"source_sha256": _sha256(source),
		"outputs": written,
		"policy": "No SVG/vector primitives; all visible VFX replacements are raster PNG frames with alpha falloff.",
	}
	manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
	written.append(str(manifest_path.relative_to(ROOT)))
	update_index(manifest_path, [fire_sheet, active_sheet], reference_path)

	print(f"wrote {len(written)} active/fire VFX artifacts")
	for path in written:
		print(path)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
