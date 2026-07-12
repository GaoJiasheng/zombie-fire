#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
VFX_DIR = PROD / "sprites" / "vfx"
SEQ_DIR = PROD / "sprites" / "vfx_sequences"
CONTACT_DIR = PROD / "contact_sheets"
SOURCE_DIR = PROD / "source_refs" / "generated"
INDEX_PATH = PROD / "OUTSOURCER_ASSET_INDEX.json"
STAMP = "2026_07_08"
RNG = random.Random(2026070817)


def rel(path: Path) -> str:
	return str(path.relative_to(ROOT))


def clean_alpha(img: Image.Image, floor: int = 6) -> Image.Image:
	out = img.convert("RGBA")
	alpha = out.getchannel("A")
	alpha = alpha.point(lambda value: 0 if value <= floor else int(255 * (((value - floor) / max(1, 255 - floor)) ** 0.9)))
	out.putalpha(alpha)
	return out


def edge_feather(img: Image.Image, margin: int = 18) -> Image.Image:
	out = img.convert("RGBA")
	w, h = out.size
	mask = Image.new("L", (w, h), 0)
	draw = ImageDraw.Draw(mask)
	draw.rounded_rectangle((margin, margin, w - margin - 1, h - margin - 1), radius=margin, fill=255)
	mask = mask.filter(ImageFilter.GaussianBlur(max(2, margin // 2)))
	alpha = ImageChops.multiply(out.getchannel("A"), mask)
	out.putalpha(alpha)
	return out


def alpha_centroid(img: Image.Image) -> tuple[float, float]:
	alpha = np.asarray(img.getchannel("A"), dtype=np.float32)
	ys, xs = np.nonzero(alpha > 8)
	if len(xs) == 0:
		return (img.width * 0.5, img.height * 0.5)
	weights = alpha[ys, xs]
	total = float(weights.sum())
	return (float((xs * weights).sum() / total), float((ys * weights).sum() / total))


def recenter(img: Image.Image, target_x: float | None = None, target_y: float | None = None) -> Image.Image:
	cx, cy = alpha_centroid(img)
	tx = img.width * 0.5 if target_x is None else target_x
	ty = img.height * 0.52 if target_y is None else target_y
	dx = int(round(tx - cx))
	dy = int(round(ty - cy))
	if dx == 0 and dy == 0:
		return img
	canvas = Image.new("RGBA", img.size, (0, 0, 0, 0))
	canvas.alpha_composite(img, (dx, dy))
	return canvas


def max_premult(a: Image.Image, b: Image.Image) -> Image.Image:
	a_arr = np.asarray(a.convert("RGBA"), dtype=np.float32)
	b_arr = np.asarray(b.convert("RGBA"), dtype=np.float32)
	pa = a_arr[:, :, :3] * (a_arr[:, :, 3:4] / 255.0)
	pb = b_arr[:, :, :3] * (b_arr[:, :, 3:4] / 255.0)
	alpha = np.maximum(a_arr[:, :, 3], b_arr[:, :, 3])
	premult = np.maximum(pa, pb)
	rgb = np.zeros_like(premult)
	mask = alpha > 0
	rgb[mask] = premult[mask] / (alpha[mask, None] / 255.0)
	out = np.dstack([np.clip(rgb, 0, 255), np.clip(alpha, 0, 255)]).astype(np.uint8)
	return Image.fromarray(out, "RGBA")


def add_center_heat(img: Image.Image, color: tuple[int, int, int], strength: float) -> Image.Image:
	w, h = img.size
	heat = Image.new("RGBA", img.size, (0, 0, 0, 0))
	pixels = heat.load()
	cx, cy = w * 0.5, h * 0.56
	radius = min(w, h) * 0.32
	for y in range(h):
		for x in range(w):
			d = math.hypot((x - cx) / radius, (y - cy) / (radius * 0.78))
			a = max(0.0, 1.0 - d) ** 2.1
			if a > 0.0:
				pixels[x, y] = (color[0], color[1], color[2], int(118 * strength * a))
	heat = heat.filter(ImageFilter.GaussianBlur(5))
	return Image.alpha_composite(heat, img)


def centered_from_existing(path: Path, kind: str, frame_index: int, total_frames: int) -> Image.Image:
	img = Image.open(path).convert("RGBA")
	img = clean_alpha(img, 9)
	mirrored = ImageOps.mirror(img)
	sym = max_premult(img, mirrored)
	sym = recenter(sym, img.width * 0.5, img.height * (0.55 if kind == "hit" else 0.54))
	sym = add_center_heat(sym, (255, 112, 28), 0.55 if kind == "hit" else 0.72)
	sym = edge_feather(sym, 18)
	# Subtle frame-dependent shimmer keeps the mirrored source from reading as a flat copy.
	d = ImageDraw.Draw(sym, "RGBA")
	p = frame_index / max(1, total_frames - 1)
	for i in range(10 if kind == "hit" else 18):
		angle = RNG.random() * math.tau
		r0 = (48 if kind == "hit" else 78) + RNG.random() * (70 if kind == "hit" else 132) * (0.45 + p)
		x = sym.width * 0.5 + math.cos(angle) * r0
		y = sym.height * 0.55 + math.sin(angle) * r0 * 0.72
		a = int((96 if kind == "hit" else 128) * (1.0 - p * 0.42) * RNG.uniform(0.45, 1.0))
		r = RNG.uniform(1.0, 3.0 if kind == "hit" else 4.4)
		d.ellipse((x - r, y - r, x + r, y + r), fill=(255, RNG.randint(126, 218), RNG.randint(36, 72), a))
	return clean_alpha(sym.filter(ImageFilter.GaussianBlur(0.25)), 5)


def radial_layer(size: tuple[int, int], center: tuple[float, float], color: tuple[int, int, int, int], radius: float, y_scale: float = 1.0, power: float = 2.0) -> Image.Image:
	w, h = size
	out = Image.new("RGBA", size, (0, 0, 0, 0))
	px = out.load()
	cx, cy = center
	for y in range(h):
		for x in range(w):
			d = math.hypot((x - cx) / max(radius, 1.0), (y - cy) / max(radius * y_scale, 1.0))
			a = max(0.0, 1.0 - d) ** power
			if a > 0:
				px[x, y] = (color[0], color[1], color[2], int(color[3] * a))
	return out


def make_enrage_frame(idx: int, count: int) -> Image.Image:
	size = (640, 640)
	p = idx / max(1, count - 1)
	pulse = math.sin(p * math.pi)
	cx, cy = 320.0, 348.0
	img = Image.new("RGBA", size, (0, 0, 0, 0))
	img.alpha_composite(radial_layer(size, (cx, cy), (255, 48, 18, int(112 + 70 * pulse)), 150 + 130 * pulse, 0.78, 1.8))
	img.alpha_composite(radial_layer(size, (cx, cy + 10), (255, 184, 44, int(132 + 88 * pulse)), 68 + 46 * pulse, 0.68, 2.35))
	img.alpha_composite(radial_layer(size, (cx, cy + 12), (255, 244, 180, int(164 + 70 * pulse)), 22 + 18 * pulse, 0.7, 2.6))
	d = ImageDraw.Draw(img, "RGBA")
	local_rng = random.Random(94000 + idx * 97)
	for i in range(34):
		angle = local_rng.uniform(0, math.tau)
		r0 = local_rng.uniform(18, 72)
		r1 = local_rng.uniform(95, 245 + 90 * pulse)
		wiggle = local_rng.uniform(-0.34, 0.34)
		points = []
		for step in range(5):
			t = step / 4.0
			a = angle + math.sin(t * math.pi + idx * 0.3) * wiggle
			r = r0 * (1 - t) + r1 * t
			points.append((cx + math.cos(a) * r, cy + math.sin(a) * r * 0.72))
		alpha = int(local_rng.uniform(34, 120) * (0.35 + pulse * 0.65))
		color = (255, local_rng.randint(70, 176), local_rng.randint(22, 48), alpha)
		d.line(points, fill=color, width=local_rng.randint(2, 5), joint="curve")
	for i in range(44):
		angle = local_rng.uniform(0, math.tau)
		r = local_rng.uniform(60, 270 + 90 * pulse)
		x = cx + math.cos(angle) * r
		y = cy + math.sin(angle) * r * 0.72
		s = local_rng.uniform(1.5, 5.0)
		a = int(local_rng.uniform(34, 148) * (0.5 + 0.5 * pulse) * (1.0 - p * 0.28))
		d.ellipse((x - s, y - s, x + s, y + s), fill=(255, local_rng.randint(92, 210), local_rng.randint(26, 58), a))
	for i in range(24):
		angle = local_rng.uniform(0, math.tau)
		r = local_rng.uniform(52, 210 + 84 * pulse)
		x = cx + math.cos(angle) * r
		y = cy + math.sin(angle) * r * 0.64 + local_rng.uniform(-8, 8)
		wisp_len = local_rng.uniform(10, 34) * (0.65 + pulse * 0.5)
		wisp_angle = angle + local_rng.uniform(-0.65, 0.65)
		alpha = int(local_rng.uniform(18, 58) * pulse)
		if alpha > 0:
			d.line(
				[
					(x, y),
					(x + math.cos(wisp_angle) * wisp_len, y + math.sin(wisp_angle) * wisp_len * 0.7),
				],
				fill=(255, local_rng.randint(76, 146), local_rng.randint(20, 42), alpha),
				width=local_rng.randint(1, 3),
			)
	img = img.filter(ImageFilter.GaussianBlur(1.15))
	crisp = Image.new("RGBA", size, (0, 0, 0, 0))
	cd = ImageDraw.Draw(crisp, "RGBA")
	for i in range(18):
		angle = local_rng.uniform(0, math.tau)
		r = local_rng.uniform(18, 116 + 80 * pulse)
		x = cx + math.cos(angle) * r
		y = cy + math.sin(angle) * r * 0.72
		s = local_rng.uniform(1.0, 3.0)
		cd.ellipse((x - s, y - s, x + s, y + s), fill=(255, 220, 88, int(122 * pulse)))
	img = Image.alpha_composite(img, crisp)
	return edge_feather(clean_alpha(img, 4), 24)


def write_sequence(sequence_id: str, frames: list[Image.Image], fps: int, source: str, integration: str) -> list[str]:
	out_dir = SEQ_DIR / sequence_id
	out_dir.mkdir(parents=True, exist_ok=True)
	outputs: list[str] = []
	frame_refs: list[str] = []
	for idx, frame in enumerate(frames, start=1):
		path = out_dir / f"{sequence_id}_{idx:02d}.png"
		frame.save(path)
		outputs.append(rel(path))
		frame_refs.append(str(path.relative_to(PROD)))
	seq_path = out_dir / f"{sequence_id}_sequence.json"
	seq_path.write_text(json.dumps({
		"id": sequence_id,
		"fps": fps,
		"frames": frame_refs,
		"source": source,
		"integration": integration,
	}, ensure_ascii=False, indent=2) + "\n")
	outputs.append(rel(seq_path))
	return outputs


def make_contact_sheet(paths: list[Path], out: Path) -> str:
	cols = 8
	cell_w, cell_h = 180, 166
	header = 58
	rows = math.ceil(len(paths) / cols)
	sheet = Image.new("RGBA", (cols * cell_w, header + rows * cell_h), (8, 11, 16, 255))
	d = ImageDraw.Draw(sheet, "RGBA")
	d.text((18, 20), "Centered fire/enrage VFX replacement - bitmap PNG sequences, no side plume", fill=(236, 242, 248, 255))
	for i, path in enumerate(paths):
		x = (i % cols) * cell_w
		y = header + (i // cols) * cell_h
		d.rounded_rectangle((x + 8, y + 8, x + cell_w - 8, y + cell_h - 8), radius=8, fill=(13, 18, 25, 255), outline=(78, 96, 112, 160), width=1)
		im = Image.open(path).convert("RGBA")
		im.thumbnail((132, 108), Image.Resampling.LANCZOS)
		sheet.alpha_composite(im, (x + (cell_w - im.width) // 2, y + 14))
		label = path.stem
		if len(label) > 26:
			label = label[:25] + "..."
		d.text((x + 12, y + 128), label, fill=(214, 226, 235, 255))
	out.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(out)
	return rel(out)


def update_index(manifest_path: Path, contact_path: Path, outputs: list[str]) -> None:
	data = json.loads(INDEX_PATH.read_text())
	overrides = data.setdefault("owner_directed_generated_overrides", [])
	entry = {
		"path": "sprites/vfx/vfx_enemy_skill_enrage.png + sprites/vfx_sequences/vfx_enemy_skill_enrage + centered fire hit/explosion sequences",
		"source": rel(manifest_path).replace("assets/production/", ""),
		"derived": rel(contact_path).replace("assets/production/", ""),
		"reason": "Owner reported a rightward fire plume on near-line ice zombies. Rebuilt enrage fallback as a centered rage pulse and centered fire hit/explosion bitmap sequences so enemy rage, hit, death, and area fire VFX no longer read as a sideways flamethrower.",
	}
	if entry not in overrides:
		overrides.append(entry)
	data.setdefault("generated_replacements", []).append({
		"path": "sprites/vfx_sequences/vfx_enemy_skill_enrage + sprites/vfx/vfx_enemy_skill_enrage.png + vfx_hit_fire/vfx_explosion_fire refresh",
		"source": rel(manifest_path),
		"derived": rel(contact_path),
		"reason": "Replace the illogical sideways fire plume with centered bitmap fire/enrage effects while preserving runtime IDs.",
		"count": len(outputs),
		"task": "centered fire and enrage VFX pass",
		"created_at": "2026-07-08T17:00:00+08:00",
	})
	counts = data.setdefault("counts", {})
	counts["total_files"] = sum(1 for path in PROD.rglob("*") if path.is_file())
	INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def main() -> int:
	outputs: list[str] = []
	source_note = "assets/production/source_refs/generated/centered_fire_enrage_vfx_2026_07_08.json"
	for sequence_id, count, fps, kind in [
		("vfx_hit_fire", 12, 22, "hit"),
		("vfx_explosion_fire", 16, 20, "explosion"),
	]:
		frames: list[Image.Image] = []
		for idx in range(1, count + 1):
			path = SEQ_DIR / sequence_id / f"{sequence_id}_{idx:02d}.png"
			frames.append(centered_from_existing(path, kind, idx - 1, count))
		outputs += write_sequence(
			sequence_id,
			frames,
			fps,
			source_note,
			"Local bitmap rerender from accepted fire reference frames: mirrored, centered, alpha-cleaned and heat-polished to remove side-plume directionality; PNG only, no SVG/vector primitives.",
		)
		single_frame = frames[6 if sequence_id == "vfx_hit_fire" else 8]
		single_path = VFX_DIR / f"{sequence_id}.png"
		single_frame.save(single_path)
		outputs.append(rel(single_path))

	enrage_frames = [make_enrage_frame(idx, 12) for idx in range(12)]
	outputs += write_sequence(
		"vfx_enemy_skill_enrage",
		enrage_frames,
		20,
		source_note,
		"Local bitmap rerender as a centered red-orange rage pulse with sparks and heat haze; no directional flame jet and no SVG/vector primitives.",
	)
	enrage_single = VFX_DIR / "vfx_enemy_skill_enrage.png"
	enrage_frames[5].save(enrage_single)
	outputs.append(rel(enrage_single))

	contact_inputs: list[Path] = []
	for seq in ["vfx_enemy_skill_enrage", "vfx_hit_fire", "vfx_explosion_fire"]:
		contact_inputs += sorted((SEQ_DIR / seq).glob("*.png"))
	contact_path = CONTACT_DIR / f"contact_centered_fire_enrage_vfx_{STAMP}.png"
	contact_rel = make_contact_sheet(contact_inputs, contact_path)
	outputs.append(contact_rel)

	SOURCE_DIR.mkdir(parents=True, exist_ok=True)
	manifest_path = SOURCE_DIR / f"centered_fire_enrage_vfx_{STAMP}.json"
	manifest = {
		"id": f"centered_fire_enrage_vfx_{STAMP}",
		"problem": "Near-line ice enemies could show an illogical sideways fire plume when enrage or fallback fire VFX used directional flame assets.",
		"outputs": outputs,
		"runtime_ids_preserved": ["vfx_enemy_skill_enrage", "vfx_hit_fire", "vfx_explosion_fire", "vfx_enemy_skill_enrage.png"],
		"policy": "All replacements are raster PNG bitmap frames with alpha falloff. No SVG, ColorRect, or vector primitive runtime substitute.",
	}
	manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
	outputs.append(rel(manifest_path))
	update_index(manifest_path, contact_path, outputs)
	print("Centered fire/enrage VFX regenerated:")
	for item in outputs:
		print("-", item)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
