#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import math
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
GENERATED_SOURCE = Path(
	"/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/"
	"exec-37e331ee-766e-4ae0-8fe0-8b181feaf537.png"
)
SOURCE_DIR = ROOT / "assets/production/source_refs/generated/blaze_meltdown_vfx_reframe_2026_07_14"
SOURCE_PATH = SOURCE_DIR / "blaze_meltdown_sprite_sheet_candidate.png"
OUTPUT_DIR = ROOT / "assets/production/sprites/vfx_sequences/vfx_active_sig_blaze_meltdown"
CONTACT_PATH = ROOT / "assets/production/contact_sheets/contact_blaze_meltdown_safe_sequence_2026_07_14.png"
FRAME_COUNT = 14
FRAME_SIZE = 768
FPS = 20


def load_regen_module():
	script = ROOT / "tools/regenerate_active_skill_vfx_2026_07_06.py"
	spec = importlib.util.spec_from_file_location("active_vfx_regen", script)
	if spec is None or spec.loader is None:
		raise RuntimeError(f"Unable to load {script}")
	module = importlib.util.module_from_spec(spec)
	spec.loader.exec_module(module)
	return module


def extract_cells(sheet: Image.Image, regen) -> list[Image.Image]:
	cell_width = sheet.width // 4
	cell_height = sheet.height // 2
	cells: list[Image.Image] = []
	for index in range(8):
		row, column = divmod(index, 4)
		x0 = column * cell_width
		y0 = row * cell_height
		x1 = sheet.width if column == 3 else (column + 1) * cell_width
		y1 = sheet.height if row == 1 else (row + 1) * cell_height
		cells.append(regen.black_to_alpha(sheet.crop((x0, y0, x1, y1))))
	return cells


def align_cells(cells: list[Image.Image], regen) -> list[Image.Image]:
	bounds = [regen.alpha_bbox(cell, 8) for cell in cells]
	max_width = max(right - left for left, _, right, _ in bounds)
	max_height = max(bottom - top for _, top, _, bottom in bounds)
	# Keep the peak plume inside a generous safe area even after the in-game 1.2x cast scale.
	scale = min(FRAME_SIZE * 0.70 / max_width, FRAME_SIZE * 0.70 / max_height)
	anchor = (FRAME_SIZE // 2, int(FRAME_SIZE * 0.82))
	aligned: list[Image.Image] = []
	for cell, bbox in zip(cells, bounds):
		content = cell.crop(bbox)
		new_size = (
			max(1, round(content.width * scale)),
			max(1, round(content.height * scale)),
		)
		content = content.resize(new_size, Image.Resampling.LANCZOS)
		content = ImageEnhance.Sharpness(content).enhance(1.12)
		canvas = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
		x = anchor[0] - content.width // 2
		y = anchor[1] - content.height
		canvas.alpha_composite(content, (x, y))
		aligned.append(canvas)
	return aligned


def resample(cells: list[Image.Image]) -> list[Image.Image]:
	frames: list[Image.Image] = []
	for index in range(FRAME_COUNT):
		position = index * (len(cells) - 1) / (FRAME_COUNT - 1)
		lower = int(math.floor(position))
		upper = min(len(cells) - 1, lower + 1)
		amount = position - lower
		frame = cells[lower].copy() if lower == upper else Image.blend(cells[lower], cells[upper], amount)
		frames.append(frame)
	return frames


def polish(frame: Image.Image) -> Image.Image:
	alpha = frame.getchannel("A")
	glow_alpha = alpha.filter(ImageFilter.GaussianBlur(13)).point(lambda value: round(value * 0.34))
	glow = Image.new("RGBA", frame.size, (255, 92, 18, 0))
	glow.putalpha(glow_alpha)
	return Image.alpha_composite(glow, frame)


def build_contact_sheet(frames: list[Image.Image]) -> None:
	thumb = 210
	gap = 18
	left = 26
	top = 72
	width = left * 2 + thumb * 7 + gap * 6
	height = top + thumb * 2 + gap + 44
	sheet = Image.new("RGB", (width, height), (8, 13, 19))
	draw = ImageDraw.Draw(sheet)
	draw.text((left, 22), "Blaze Meltdown - safe-frame production sequence", fill=(232, 239, 245))
	for index, frame in enumerate(frames):
		row, column = divmod(index, 7)
		x = left + column * (thumb + gap)
		y = top + row * (thumb + gap)
		preview = frame.resize((thumb, thumb), Image.Resampling.LANCZOS)
		sheet.paste(preview.convert("RGB"), (x, y), preview.getchannel("A"))
		draw.rectangle((x, y, x + thumb - 1, y + thumb - 1), outline=(45, 60, 72), width=1)
		draw.text((x + 8, y + thumb - 25), f"F{index + 1:02d}", fill=(174, 187, 197))
	CONTACT_PATH.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(CONTACT_PATH, quality=95)


def main() -> None:
	SOURCE_DIR.mkdir(parents=True, exist_ok=True)
	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
	if not SOURCE_PATH.exists():
		if not GENERATED_SOURCE.exists():
			raise FileNotFoundError(f"Missing both checked-in source and generation cache: {SOURCE_PATH}")
		shutil.copy2(GENERATED_SOURCE, SOURCE_PATH)
	regen = load_regen_module()
	sheet = Image.open(SOURCE_PATH).convert("RGB")
	frames = [polish(frame) for frame in resample(align_cells(extract_cells(sheet, regen), regen))]
	paths: list[str] = []
	for index, frame in enumerate(frames, start=1):
		path = OUTPUT_DIR / f"vfx_active_sig_blaze_meltdown_{index:02d}.png"
		frame.save(path)
		paths.append(str(path.relative_to(ROOT / "assets/production")))
	metadata = {
		"id": "vfx_active_sig_blaze_meltdown",
		"fps": FPS,
		"frames": paths,
		"source": str(SOURCE_PATH.relative_to(ROOT)),
		"status": "integrated_2026_07_14",
		"integration": "AI-rendered 4x2 reference with fixed ground anchor and safe margins; PNG bitmap sequence, no SVG/vector primitives",
	}
	(OUTPUT_DIR / "vfx_active_sig_blaze_meltdown_sequence.json").write_text(
		json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
		encoding="utf-8",
	)
	build_contact_sheet(frames)
	print(CONTACT_PATH)


if __name__ == "__main__":
	main()
