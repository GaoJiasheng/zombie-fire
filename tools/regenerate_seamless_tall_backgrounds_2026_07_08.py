#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageOps


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
BG_DIR = PROD / "sprites" / "backgrounds"
ENV_DIR = PROD / "environment"
CONTACT_DIR = PROD / "contact_sheets"
SOURCE_DIR = PROD / "source_refs" / "generated" / "seamless_tall_battle_backgrounds_2026_07_08"
INDEX_PATH = PROD / "OUTSOURCER_ASSET_INDEX.json"

TARGET_SIZE = (1080, 2622)

CAMPAIGN_BACKGROUNDS = [
	("env_lava_foundry", "bg_lava_foundry", 194),
	("env_glacier_pass", "bg_glacier_pass", 192),
	("env_abandoned_factory", "bg_abandoned_factory", 0),
	("env_toxic_biolab", "bg_toxic_biolab", 112),
	("env_storm_substation", "bg_storm_substation", 68),
	("env_flooded_subway", "bg_flooded_subway", 172),
	("env_desert_refinery", "bg_desert_refinery", 96),
	("env_void_cathedral", "bg_void_cathedral", 114),
	("env_orbital_ruins", "bg_orbital_ruins", 148),
	("env_apex_core", "bg_apex_core", 112),
]


def _sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def _cover_crop(image: Image.Image, size: tuple[int, int]) -> Image.Image:
	return ImageOps.fit(image.convert("RGB"), size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))


def _smoothstep(value: np.ndarray) -> np.ndarray:
	value = np.clip(value, 0.0, 1.0)
	return value * value * (3.0 - 2.0 * value)


def _shift_with_seamless_top(source: Image.Image, shift_down: int, seed: int) -> Image.Image:
	source = source.convert("RGB")
	if shift_down <= 0:
		return source
	_ = seed
	arr = np.asarray(source, dtype=np.float32)
	height, width, channels = arr.shape
	y = np.arange(height, dtype=np.float32)
	# The first 9% of the image remains exactly the original render. Below that,
	# the vertical alignment offset ramps in gradually and reaches the full
	# approved fortress shift before the lower combat lane. This preserves the
	# original top art and avoids creating a hard synthesized band.
	t = _smoothstep((y - height * 0.09) / (height * 0.60))
	source_y = np.clip(y - float(shift_down) * t, 0.0, float(height - 1))
	y0 = np.floor(source_y).astype(np.int32)
	y1 = np.minimum(y0 + 1, height - 1)
	frac = (source_y - y0).reshape(height, 1, 1)
	warped = arr[y0, :, :] * (1.0 - frac) + arr[y1, :, :] * frac
	return Image.fromarray(np.clip(warped, 0.0, 255.0).astype(np.uint8))


def _luma(image: Image.Image) -> np.ndarray:
	arr = np.asarray(image.convert("RGB"), dtype=np.float32)
	return arr[:, :, 0] * 0.2126 + arr[:, :, 1] * 0.7152 + arr[:, :, 2] * 0.0722


def _top_metrics(image: Image.Image) -> dict:
	top = image.crop((0, 0, image.width, min(260, image.height)))
	lum = _luma(top)
	return {
		"mean_luma": round(float(lum.mean()), 2),
		"std_luma": round(float(lum.std()), 2),
		"dark_lt_18": round(float((lum < 18.0).mean()), 4),
	}


def _boundary_delta(image: Image.Image, y: int) -> float:
	y = max(18, min(image.height - 19, y))
	upper = image.crop((0, y - 18, image.width, y))
	lower = image.crop((0, y, image.width, y + 18))
	diff = ImageChops.difference(upper, lower)
	return round(float(np.asarray(diff.convert("L"), dtype=np.float32).mean()), 2)


def _make_contact_sheet(outputs: list[tuple[str, Image.Image]]) -> Path:
	CONTACT_DIR.mkdir(parents=True, exist_ok=True)
	cell_w, cell_h = 270, 656
	label_h = 34
	cols = 5
	rows = 2
	sheet = Image.new("RGB", (cols * cell_w, rows * (cell_h + label_h)), (8, 12, 16))
	draw = ImageDraw.Draw(sheet)
	for idx, (name, image) in enumerate(outputs):
		x = (idx % cols) * cell_w
		y = (idx // cols) * (cell_h + label_h)
		thumb = image.resize((cell_w, cell_h), Image.Resampling.LANCZOS)
		sheet.paste(thumb, (x, y))
		draw.rectangle((x, y + cell_h, x + cell_w, y + cell_h + label_h), fill=(12, 18, 24))
		draw.text((x + 8, y + cell_h + 9), name, fill=(220, 229, 235))
	contact = CONTACT_DIR / "contact_seamless_tall_battle_backgrounds_2026_07_08.png"
	sheet.save(contact, quality=95)
	return contact


def _update_index(manifest_path: Path, contact_path: Path) -> None:
	data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
	overrides = data.setdefault("owner_directed_generated_overrides", [])
	source_ref = str(manifest_path.relative_to(PROD))
	overrides[:] = [
		item for item in overrides
		if not (item.get("source") == source_ref and item.get("path") == "sprites/backgrounds")
	]
	overrides.append(
		{
			"path": "sprites/backgrounds",
			"source": source_ref,
			"derived": str(contact_path.relative_to(PROD)),
			"reason": "Owner reported the previous tall-screen top extension still looked abrupt. Rebuilt all ten campaign battle backgrounds from the original full-height 1206x2622 rendered environment sources, then reapplied fortress alignment as a shallow top-safe shift instead of a 702px mirrored extension.",
		}
	)
	counts = data.setdefault("counts", {})
	counts["background_files"] = len(list((PROD / "sprites" / "backgrounds").glob("*.png")))
	counts["total_files"] = len([p for p in PROD.rglob("*") if p.is_file()])
	INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
	SOURCE_DIR.mkdir(parents=True, exist_ok=True)
	outputs: list[tuple[str, Image.Image]] = []
	manifest = {
		"id": "seamless_tall_battle_backgrounds_2026_07_08",
		"generated_by": "tools/regenerate_seamless_tall_backgrounds_2026_07_08.py",
		"source_mode": "Reintegrated from existing top-tier full-height 1206x2622 rendered environment portraits; no vector/SVG fallback.",
		"target_size": list(TARGET_SIZE),
		"policy": "Use the original full-height environment render as the base, apply the previously approved fortress alignment as a shallow downward shift, and synthesize only the small shift-height top strip with feathered blending.",
		"backgrounds": [],
	}
	for idx, (env_id, bg_name, shift_down) in enumerate(CAMPAIGN_BACKGROUNDS):
		portrait_path = ENV_DIR / f"{bg_name}_portrait.png"
		output_path = BG_DIR / f"{bg_name}.png"
		if not portrait_path.exists():
			raise FileNotFoundError(portrait_path)
		before_hash = _sha256(output_path)
		source = _cover_crop(Image.open(portrait_path), TARGET_SIZE)
		rebuilt = _shift_with_seamless_top(source, shift_down, 8800 + idx * 131)
		rebuilt.save(output_path, optimize=True)
		after_hash = _sha256(output_path)
		outputs.append((env_id, rebuilt))
		manifest["backgrounds"].append(
			{
				"env_id": env_id,
				"path": str(output_path.relative_to(PROD)),
				"source_portrait": str(portrait_path.relative_to(PROD)),
				"before_sha256": before_hash,
				"after_sha256": after_hash,
				"alignment_shift_down_px": shift_down,
				"top_metrics": _top_metrics(rebuilt),
				"shift_boundary_luma_delta": _boundary_delta(rebuilt, shift_down) if shift_down > 0 else 0.0,
				"old_extension_boundary_702_delta": _boundary_delta(rebuilt, 702),
			}
		)

	contact_path = _make_contact_sheet(outputs)
	manifest["contact_sheet"] = str(contact_path.relative_to(PROD))
	manifest_path = SOURCE_DIR / "seamless_tall_battle_backgrounds_manifest_2026_07_08.json"
	manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	_update_index(manifest_path, contact_path)
	print(f"Regenerated {len(outputs)} seamless tall battle backgrounds to {TARGET_SIZE[0]}x{TARGET_SIZE[1]}")
	print(f"Manifest: {manifest_path.relative_to(ROOT)}")
	print(f"Contact sheet: {contact_path.relative_to(ROOT)}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
