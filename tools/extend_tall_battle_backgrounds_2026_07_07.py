#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
BG_DIR = PROD / "sprites" / "backgrounds"
CONTACT_DIR = PROD / "contact_sheets"
SOURCE_DIR = PROD / "source_refs" / "generated" / "tall_battle_background_extension_2026_07_07"
INDEX_PATH = PROD / "OUTSOURCER_ASSET_INDEX.json"

DESIGN_SIZE = (1080, 1920)
TARGET_SIZE = (1080, 2622)
EXTRA_TOP = TARGET_SIZE[1] - DESIGN_SIZE[1]

CAMPAIGN_BACKGROUNDS = [
	"bg_lava_foundry.png",
	"bg_glacier_pass.png",
	"bg_abandoned_factory.png",
	"bg_toxic_biolab.png",
	"bg_storm_substation.png",
	"bg_flooded_subway.png",
	"bg_desert_refinery.png",
	"bg_void_cathedral.png",
	"bg_orbital_ruins.png",
	"bg_apex_core.png",
]


def _sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def _luminance_array(image: Image.Image) -> np.ndarray:
	arr = np.asarray(image.convert("RGB"), dtype=np.float32)
	return arr[:, :, 0] * 0.2126 + arr[:, :, 1] * 0.7152 + arr[:, :, 2] * 0.0722


def _top_metrics(image: Image.Image, top_h: int = 240) -> dict:
	band = image.crop((0, 0, image.width, min(top_h, image.height)))
	lum = _luminance_array(band)
	return {
		"mean_luma": round(float(lum.mean()), 2),
		"std_luma": round(float(lum.std()), 2),
		"dark_lt_18": round(float((lum < 18.0).mean()), 4),
		"very_dark_lt_10": round(float((lum < 10.0).mean()), 4),
	}


def _theme_color(image: Image.Image) -> np.ndarray:
	arr = np.asarray(image.convert("RGB"), dtype=np.float32)
	band = arr[: min(920, arr.shape[0]), :, :]
	lum = band[:, :, 0] * 0.2126 + band[:, :, 1] * 0.7152 + band[:, :, 2] * 0.0722
	mask = lum > np.percentile(lum, 58)
	if mask.any():
		color = band[mask].mean(axis=0)
	else:
		color = band.reshape(-1, 3).mean(axis=0)
	return np.clip(color, 18.0, 150.0)


def _lift_shadows(image: Image.Image, theme: np.ndarray, strength: float) -> Image.Image:
	arr = np.asarray(image.convert("RGB"), dtype=np.float32)
	lum = arr[:, :, 0] * 0.2126 + arr[:, :, 1] * 0.7152 + arr[:, :, 2] * 0.0722
	shadow = np.clip((44.0 - lum) / 44.0, 0.0, 1.0) ** 1.25
	theme_layer = theme.reshape(1, 1, 3)
	arr = arr * (1.0 + 0.10 * strength)
	arr += shadow[:, :, None] * (theme_layer * 0.24 + 16.0) * strength
	arr = np.clip(arr, 0.0, 255.0)
	return Image.fromarray(arr.astype(np.uint8))


def _add_fine_grain(image: Image.Image, amount: float, seed: int) -> Image.Image:
	rng = np.random.default_rng(seed)
	arr = np.asarray(image.convert("RGB"), dtype=np.float32)
	noise = rng.normal(0.0, amount, arr.shape[:2]).astype(np.float32)
	arr += noise[:, :, None]
	return Image.fromarray(np.clip(arr, 0.0, 255.0).astype(np.uint8))


def _enhance_top_of_original(original: Image.Image, seed: int) -> Image.Image:
	image = original.convert("RGB")
	theme = _theme_color(image)
	top_h = 520
	source = image.crop((0, 110, image.width, min(930, image.height))).resize((image.width, top_h), Image.Resampling.BICUBIC)
	source = source.filter(ImageFilter.GaussianBlur(0.9))
	source = _lift_shadows(source, theme, 0.76)
	source = ImageEnhance.Contrast(source).enhance(1.10)
	source = ImageEnhance.Sharpness(source).enhance(1.25)

	base_top = image.crop((0, 0, image.width, top_h))
	mask = Image.new("L", (image.width, top_h), 0)
	draw = ImageDraw.Draw(mask)
	for y in range(top_h):
		alpha = int(210 * max(0.0, 1.0 - (y / float(top_h - 1))) ** 1.35)
		draw.line([(0, y), (image.width, y)], fill=alpha)
	top = Image.composite(source, base_top, mask)
	top = _lift_shadows(top, theme, 0.50)
	top = _add_fine_grain(top, 2.8, seed)

	fixed = image.copy()
	fixed.paste(top, (0, 0))
	return fixed


def _build_top_extension(fixed_original: Image.Image, seed: int) -> Image.Image:
	theme = _theme_color(fixed_original)
	seed_crop = fixed_original.crop((0, 0, fixed_original.width, EXTRA_TOP)).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
	context = fixed_original.crop((0, 0, fixed_original.width, min(1040, fixed_original.height))).resize(
		(fixed_original.width, EXTRA_TOP),
		Image.Resampling.BICUBIC,
	)
	context = context.filter(ImageFilter.GaussianBlur(1.1))
	extension = Image.blend(seed_crop, context, 0.42)
	extension = _lift_shadows(extension, theme, 0.88)
	extension = ImageEnhance.Contrast(extension).enhance(1.12)
	extension = ImageEnhance.Sharpness(extension).enhance(1.18)
	extension = _add_fine_grain(extension, 3.2, seed + 101)

	# Keep the seam where the original 1920px canvas starts invisible: the last
	# strip of the extension blends into the first strip of the fixed original.
	seam_h = 150
	match = fixed_original.crop((0, 0, fixed_original.width, seam_h))
	ext_arr = np.asarray(extension.convert("RGB"), dtype=np.float32)
	match_arr = np.asarray(match.convert("RGB"), dtype=np.float32)
	for row in range(seam_h):
		t = (row + 1) / float(seam_h)
		t = t * t * (3.0 - 2.0 * t)
		y = EXTRA_TOP - seam_h + row
		ext_arr[y, :, :] = ext_arr[y, :, :] * (1.0 - t) + match_arr[row, :, :] * t
	return Image.fromarray(np.clip(ext_arr, 0.0, 255.0).astype(np.uint8))


def _extend_background(path: Path, seed: int) -> tuple[Image.Image, dict]:
	original = Image.open(path).convert("RGB")
	if original.size != DESIGN_SIZE:
		original = original.resize(DESIGN_SIZE, Image.Resampling.LANCZOS)
	before = _top_metrics(original)
	fixed_original = _enhance_top_of_original(original, seed)
	extension = _build_top_extension(fixed_original, seed)
	extended = Image.new("RGB", TARGET_SIZE)
	extended.paste(extension, (0, 0))
	extended.paste(fixed_original, (0, EXTRA_TOP))
	after = _top_metrics(extended)
	return extended, {"before": before, "after": after}


def _make_contact_sheet(outputs: list[tuple[str, Image.Image]]) -> Path:
	CONTACT_DIR.mkdir(parents=True, exist_ok=True)
	cell_w, cell_h = 270, 660
	label_h = 34
	cols = 5
	rows = 2
	sheet = Image.new("RGB", (cols * cell_w, rows * (cell_h + label_h)), (9, 13, 18))
	draw = ImageDraw.Draw(sheet)
	for idx, (name, image) in enumerate(outputs):
		x = (idx % cols) * cell_w
		y = (idx // cols) * (cell_h + label_h)
		thumb = image.resize((cell_w, cell_h), Image.Resampling.LANCZOS)
		sheet.paste(thumb, (x, y))
		draw.rectangle((x, y + cell_h, x + cell_w, y + cell_h + label_h), fill=(12, 18, 24))
		draw.text((x + 8, y + cell_h + 9), name.removesuffix(".png"), fill=(218, 226, 232))
	contact = CONTACT_DIR / "contact_tall_battle_backgrounds_2026_07_07.png"
	sheet.save(contact)
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
			"reason": "Owner screenshot showed high-screen battle top area reading as a black blank band. Campaign battle backgrounds were extended to 1080x2622 with bottom composition preserved so tall devices use rendered environment art instead of a runtime black gradient extension.",
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
		"id": "tall_battle_background_extension_2026_07_07",
		"generated_by": "tools/extend_tall_battle_backgrounds_2026_07_07.py",
		"target_size": list(TARGET_SIZE),
		"policy": "Original 1080x1920 battle composition is preserved at the bottom of a 1080x2622 canvas; top extension is rendered from the same environment image with lifted detail and seam blending.",
		"backgrounds": [],
	}
	for idx, name in enumerate(CAMPAIGN_BACKGROUNDS):
		path = BG_DIR / name
		before_hash = _sha256(path)
		extended, metrics = _extend_background(path, 7700 + idx * 97)
		extended.save(path)
		after_hash = _sha256(path)
		outputs.append((name, extended))
		manifest["backgrounds"].append(
			{
				"path": str(path.relative_to(PROD)),
				"before_sha256": before_hash,
				"after_sha256": after_hash,
				"before_top240": metrics["before"],
				"after_top240": metrics["after"],
			}
		)

	contact_path = _make_contact_sheet(outputs)
	manifest_path = SOURCE_DIR / "tall_battle_background_extension_manifest_2026_07_07.json"
	manifest["contact_sheet"] = str(contact_path.relative_to(PROD))
	manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	_update_index(manifest_path, contact_path)
	print(f"Extended {len(outputs)} campaign battle backgrounds to {TARGET_SIZE[0]}x{TARGET_SIZE[1]}")
	print(f"Manifest: {manifest_path.relative_to(ROOT)}")
	print(f"Contact sheet: {contact_path.relative_to(ROOT)}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
