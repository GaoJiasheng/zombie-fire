#!/usr/bin/env python3
from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets/production/source_refs/generated/menu_title_logo_2026_07_10"
SOURCE = SOURCE_DIR / "imagegen_title_source.png"
OUT = ROOT / "assets/production/sprites/ui/ui_menu_title_shichao_fangxian.png"
SOURCE_REF = SOURCE_DIR / "menu_title_logo_2026_07_10.md"
INDEX = ROOT / "assets/production/OUTSOURCER_ASSET_INDEX.json"

TEXT = "尸潮防线"
CANVAS_SIZE = (1080, 360)
MAX_TITLE_SIZE = (1060, 338)


def _remove_checker_background(src: Image.Image) -> Image.Image:
	"""Turn the AI tool's white checkerboard preview into a real alpha channel."""
	img = src.convert("RGBA")
	rgba = img.load()
	alpha = Image.new("L", img.size, 0)
	ap = alpha.load()
	for y in range(img.height):
		for x in range(img.width):
			r, g, b, _a = rgba[x, y]
			hi = max(r, g, b)
			lo = min(r, g, b)
			sat = hi - lo
			luma = 0.299 * r + 0.587 * g + 0.114 * b
			if luma >= 238 and sat <= 18:
				a = 0
			elif luma <= 214 or sat >= 34:
				a = 255
			else:
				bg_luma = max(0.0, min(1.0, (luma - 214.0) / 30.0))
				bg_neutral = max(0.0, min(1.0, (34.0 - sat) / 34.0))
				a = int(255 * (1.0 - bg_luma * bg_neutral))
			ap[x, y] = a
	alpha = alpha.filter(ImageFilter.MedianFilter(3)).filter(ImageFilter.GaussianBlur(0.55))
	img.putalpha(alpha)
	return img


def _fit_to_runtime_canvas(title: Image.Image) -> Image.Image:
	bbox = title.getchannel("A").getbbox()
	if bbox is None:
		raise RuntimeError("No title pixels after alpha extraction")
	crop = title.crop(bbox)
	scale = min(MAX_TITLE_SIZE[0] / crop.width, MAX_TITLE_SIZE[1] / crop.height)
	resized = crop.resize((int(crop.width * scale), int(crop.height * scale)), Image.Resampling.LANCZOS)
	canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
	canvas.alpha_composite(resized, ((CANVAS_SIZE[0] - resized.width) // 2, (CANVAS_SIZE[1] - resized.height) // 2))
	return canvas


def render() -> None:
	OUT.parent.mkdir(parents=True, exist_ok=True)
	SOURCE_DIR.mkdir(parents=True, exist_ok=True)
	runtime = _fit_to_runtime_canvas(_remove_checker_background(Image.open(SOURCE)))
	runtime.save(OUT)
	SOURCE_REF.write_text(
		"\n".join(
			[
				"# Menu Title Logo ImageGen Render · 2026-07-10",
				"",
				f"- Runtime asset: `assets/production/sprites/ui/{OUT.name}`",
				f"- Exact title target: `{TEXT}`",
				"- Source: `assets/production/source_refs/generated/menu_title_logo_2026_07_10/imagegen_title_source.png`",
				"- Prompt intent: render the four Chinese title characters as massive hard-surface 3D models, not art text, not a runtime font, not geometric UI lines.",
				"- Processing: local script removes the image tool's checkerboard preview background, keeps the rendered 3D text pixels, fits the title to a transparent `1080x360` runtime PNG, and leaves the original generated source intact.",
				"- Visual target: cracked gunmetal/stone slabs, deep black extrusion, hard chamfered bevels, subtle orange lower heat and cyan upper rim lighting, readable at phone title-screen size.",
			]
		)
		+ "\n",
		encoding="utf-8",
	)


def update_asset_index() -> None:
	data = json.loads(INDEX.read_text(encoding="utf-8"))
	entry = {
		"path": "sprites/ui/ui_menu_title_shichao_fangxian.png",
		"source": "assets/production/source_refs/generated/menu_title_logo_2026_07_10/menu_title_logo_2026_07_10.md",
		"derived": "assets/production/sprites/ui/ui_menu_title_shichao_fangxian.png",
		"reason": "Owner rejected font/art-text title passes. Replaced the main title with an image-generated hard-surface 3D title render, then locally extracted alpha and fit it as the runtime PNG.",
		"count": 1,
		"task": "main menu rendered title logo",
		"created_at": datetime.now(timezone(timedelta(hours=8))).isoformat(timespec="seconds"),
	}
	replacements = data.setdefault("generated_replacements", [])
	replacements[:] = [item for item in replacements if item.get("path") != entry["path"]]
	replacements.append(entry)
	INDEX.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
	render()
	update_asset_index()
	print(f"processed {SOURCE.relative_to(ROOT)}")
	print(f"rendered {OUT.relative_to(ROOT)}")
	print(f"wrote {SOURCE_REF.relative_to(ROOT)}")
	print("updated assets/production/OUTSOURCER_ASSET_INDEX.json")


if __name__ == "__main__":
	main()
