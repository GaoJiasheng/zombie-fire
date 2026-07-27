#!/usr/bin/env python3
"""Build a compact review sheet from deterministic combat VFX screenshots."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageStat


DEFAULT_ORDER = [
	"runner_dash",
	"charge",
	"leap_strike",
	"boss_phase_shift",
	"toxic_cloud",
	"ranged_spit",
	"corrosion",
	"regen",
	"venom",
	"acid_spit",
	"split_mini",
	"toxic_cloud_tall",
]


def parse_args() -> argparse.Namespace:
	parser = argparse.ArgumentParser()
	parser.add_argument("input_dir", type=Path)
	parser.add_argument("output", type=Path)
	return parser.parse_args()


def fit(image: Image.Image, size: tuple[int, int]) -> Image.Image:
	background = Image.new("RGB", size, (6, 10, 13))
	copy = image.convert("RGB")
	copy.thumbnail(size, Image.Resampling.LANCZOS)
	background.paste(copy, ((size[0] - copy.width) // 2, (size[1] - copy.height) // 2))
	return background


def main() -> int:
	args = parse_args()
	paths = [(name, args.input_dir / f"{name}.png") for name in DEFAULT_ORDER]
	missing = [path for _, path in paths if not path.is_file()]
	if missing:
		for path in missing:
			print(f"missing: {path}")
		return 1
	for name, path in paths:
		with Image.open(path) as source:
			image = source.convert("RGB")
		if image.size not in {(1080, 1920), (1080, 2348)}:
			print(f"{name}: unexpected viewport {image.size}")
			return 1
		if max(ImageStat.Stat(image.resize((32, 32))).stddev) < 8.0:
			print(f"{name}: screenshot is probably blank")
			return 1

	columns = 3
	cell_width = 300
	cell_height = 570
	thumb_size = (270, 480)
	rows = (len(paths) + columns - 1) // columns
	sheet = Image.new("RGB", (columns * cell_width, 62 + rows * cell_height), (6, 10, 13))
	draw = ImageDraw.Draw(sheet)
	title_font = ImageFont.load_default(size=20)
	label_font = ImageFont.load_default(size=17)
	draw.text(
		(18, 18),
		"Runtime semantic audit - direction / origin / impact / crop / HUD",
		fill=(224, 238, 244),
		font=title_font,
	)
	for index, (name, path) in enumerate(paths):
		with Image.open(path) as source:
			thumbnail = fit(source, thumb_size)
			viewport_label = f"{source.width}x{source.height}"
		x = (index % columns) * cell_width
		y = 62 + (index // columns) * cell_height
		sheet.paste(thumbnail, (x + 15, y + 38))
		draw.text((x + 15, y + 10), name, fill=(150, 219, 232), font=label_font)
		draw.text((x + 15, y + 525), viewport_label, fill=(128, 151, 161), font=label_font)
	args.output.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(args.output, optimize=True)
	print(f"runtime audit sheet: {args.output}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
