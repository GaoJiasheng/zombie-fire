#!/usr/bin/env python3
"""One-time, reproducible repair for rejected combat VFX.

The affected sequences were legacy crops from dense reference sheets. Their
visible rectangular edges could not be repaired by adding outer padding, so
this script derives replacements from already accepted premium production
sequences while preserving every target ID, path, frame count, and data ref.
"""

from __future__ import annotations

import json
import shutil
from datetime import datetime
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
PRODUCTION = ROOT / "assets/production"
SEQUENCE_ROOT = PRODUCTION / "sprites/vfx_sequences"
PROJECTILE_ROOT = PRODUCTION / "sprites/projectiles"
SOURCE_DIR = PRODUCTION / "source_refs/generated/combat_vfx_semantic_repair_2026_07_26"
MANIFEST_PATH = SOURCE_DIR / "manifest.json"
CONTACT_PATH = PRODUCTION / "contact_sheets/contact_combat_vfx_semantic_repair_2026_07_26.png"
INDEX_PATH = PRODUCTION / "OUTSOURCER_ASSET_INDEX.json"

SEQUENCE_REPLACEMENTS = {
	"vfx_enemy_skill_corrosion": "vfx_hit_poison",
	"vfx_enemy_skill_ranged_spit": "vfx_muzzle_poison",
	"vfx_enemy_skill_toxic_cloud": "vfx_poison_cloud",
	"vfx_skill_cast_venom": "vfx_poison_cloud",
	"vfx_enemy_skill_regen": "vfx_enemy_skill_regenerate",
	"vfx_death_dissolve": "vfx_death_physical",
}

PROJECTILE_REPLACEMENTS = {
	"proj_acid_spit.png": "proj_bullet_poison.png",
	"proj_split_mini.png": "proj_scatter_pellet.png",
}


def load_json(path: Path) -> dict:
	return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, payload: dict) -> None:
	path.write_text(
		json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
		encoding="utf-8",
	)


def sequence_metadata(sequence_id: str) -> tuple[Path, dict]:
	sequence_dir = SEQUENCE_ROOT / sequence_id
	metadata_paths = sorted(sequence_dir.glob("*_sequence.json"))
	if len(metadata_paths) != 1:
		raise RuntimeError(f"{sequence_id}: expected exactly one metadata file")
	path = metadata_paths[0]
	return path, load_json(path)


def frame_path(relative: str) -> Path:
	return PRODUCTION / relative


def read_rgba(path: Path) -> Image.Image:
	with Image.open(path) as source:
		return source.convert("RGBA")


def contained_on_canvas(source: Image.Image, size: tuple[int, int]) -> Image.Image:
	"""Contain without cropping; accepted source alpha margins remain intact."""
	canvas = Image.new("RGBA", size, (0, 0, 0, 0))
	scale = min(size[0] / source.width, size[1] / source.height, 1.0)
	if scale < 1.0:
		source = source.resize(
			(max(1, round(source.width * scale)), max(1, round(source.height * scale))),
			Image.Resampling.LANCZOS,
		)
	position = ((size[0] - source.width) // 2, (size[1] - source.height) // 2)
	canvas.alpha_composite(source, position)
	return canvas


def representative_frame(sequence_id: str) -> Image.Image:
	_, metadata = sequence_metadata(sequence_id)
	frames = metadata["frames"]
	return read_rgba(frame_path(frames[len(frames) // 2]))


def repair_sequence(target_id: str, source_id: str) -> None:
	target_metadata_path, target_metadata = sequence_metadata(target_id)
	_, source_metadata = sequence_metadata(source_id)
	target_frames = list(target_metadata["frames"])
	source_frames = list(source_metadata["frames"])
	if not target_frames or not source_frames:
		raise RuntimeError(f"{target_id}: empty target/source sequence")
	target_size = read_rgba(frame_path(target_frames[0])).size
	target_count = len(target_frames)
	for index, target_relative in enumerate(target_frames):
		source_index = (
			0
			if target_count == 1
			else round(index * (len(source_frames) - 1) / (target_count - 1))
		)
		source = read_rgba(frame_path(source_frames[source_index]))
		contained_on_canvas(source, target_size).save(frame_path(target_relative))
	target_metadata["source"] = str(MANIFEST_PATH.relative_to(ROOT))
	target_metadata["integration"] = (
		f"Semantic repair derived from accepted production sequence {source_id}; "
		"contained without crop, target ID/path/frame count preserved."
	)
	save_json(target_metadata_path, target_metadata)


def checkerboard(size: tuple[int, int]) -> Image.Image:
	image = Image.new("RGB", size, (12, 18, 22))
	draw = ImageDraw.Draw(image)
	cell = 20
	for y in range(0, size[1], cell):
		for x in range(0, size[0], cell):
			if (x // cell + y // cell) % 2:
				draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=(20, 29, 34))
	return image


def preview(source: Image.Image, size: tuple[int, int]) -> Image.Image:
	background = checkerboard(size)
	scale = min(size[0] / source.width, size[1] / source.height)
	resized = source.resize(
		(max(1, round(source.width * scale)), max(1, round(source.height * scale))),
		Image.Resampling.LANCZOS,
	)
	position = ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2)
	background.paste(resized, position, resized)
	return background


def build_contact_sheet(before: dict[str, Image.Image], after: dict[str, Image.Image]) -> None:
	items = list(before)
	item_width = 590
	item_height = 290
	columns = 2
	rows = (len(items) + columns - 1) // columns
	sheet = Image.new("RGB", (item_width * columns, 54 + item_height * rows), (7, 11, 14))
	draw = ImageDraw.Draw(sheet)
	font = ImageFont.load_default(size=18)
	small = ImageFont.load_default(size=15)
	draw.text((20, 16), "Combat VFX semantic repair: BEFORE / AFTER", fill=(230, 240, 244), font=font)
	for index, item_id in enumerate(items):
		x = (index % columns) * item_width
		y = 54 + (index // columns) * item_height
		draw.text((x + 18, y + 8), item_id, fill=(184, 225, 235), font=font)
		draw.text((x + 18, y + 36), "BEFORE", fill=(235, 151, 111), font=small)
		draw.text((x + 308, y + 36), "AFTER", fill=(119, 222, 172), font=small)
		sheet.paste(preview(before[item_id], (260, 220)), (x + 18, y + 58))
		sheet.paste(preview(after[item_id], (260, 220)), (x + 308, y + 58))
	CONTACT_PATH.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(CONTACT_PATH, optimize=True)


def refresh_contact_after_panes(after: dict[str, Image.Image]) -> None:
	"""Keep the original rejection panes while refreshing final accepted panes."""
	if not CONTACT_PATH.exists():
		return
	with Image.open(CONTACT_PATH) as source:
		sheet = source.convert("RGB")
	item_width = 590
	columns = 2
	item_height = 290
	for index, item_id in enumerate(after):
		x = (index % columns) * item_width
		y = 54 + (index // columns) * item_height
		sheet.paste(preview(after[item_id], (260, 220)), (x + 308, y + 58))
	sheet.save(CONTACT_PATH, optimize=True)


def update_index() -> None:
	index = load_json(INDEX_PATH)
	task = "combat VFX semantic direction and crop acceptance repair"
	replacements = index.setdefault("generated_replacements", [])
	entry = {
		"path": (
			"sprites/vfx_sequences/{corrosion,ranged_spit,toxic_cloud,regen,"
			"death_dissolve,skill_cast_venom} + sprites/projectiles/{acid_spit,split_mini}"
		),
		"source": str(MANIFEST_PATH.relative_to(ROOT)),
		"derived": str(CONTACT_PATH.relative_to(ROOT)),
		"reason": (
			"Replace legacy reference-sheet crops and two primitive projectile silhouettes "
			"with contained derivatives of accepted premium production assets; preserve IDs, "
			"paths, frame counts, gameplay timings, and data references."
		),
		"count": 8,
		"task": task,
		"created_at": "2026-07-26T18:00:00+08:00",
	}
	for index_value, existing in enumerate(replacements):
		if existing.get("task") == task:
			replacements[index_value] = entry
			break
	else:
		replacements.append(entry)
	save_json(INDEX_PATH, index)


def main() -> int:
	before: dict[str, Image.Image] = {
		target_id: representative_frame(target_id)
		for target_id in SEQUENCE_REPLACEMENTS
	}
	before.update(
		{
			target_name.removesuffix(".png"): read_rgba(PROJECTILE_ROOT / target_name)
			for target_name in PROJECTILE_REPLACEMENTS
		}
	)
	SOURCE_DIR.mkdir(parents=True, exist_ok=True)
	manifest = {
		"id": "combat_vfx_semantic_repair_2026_07_26",
		"created_at": datetime.now().astimezone().isoformat(),
		"purpose": (
			"Repair effects rejected by direction/crop semantic acceptance without "
			"regenerating or overwriting accepted premium source artwork."
		),
		"sequence_replacements": SEQUENCE_REPLACEMENTS,
		"projectile_replacements": PROJECTILE_REPLACEMENTS,
		"constraints": [
			"preserve target IDs, paths, frame counts, fps, and gameplay data references",
			"contain source alpha without crop",
			"derive only from already accepted premium production artwork",
		],
	}
	save_json(MANIFEST_PATH, manifest)
	for target_id, source_id in SEQUENCE_REPLACEMENTS.items():
		repair_sequence(target_id, source_id)
	for target_name, source_name in PROJECTILE_REPLACEMENTS.items():
		shutil.copyfile(PROJECTILE_ROOT / source_name, PROJECTILE_ROOT / target_name)
	after: dict[str, Image.Image] = {
		target_id: representative_frame(target_id)
		for target_id in SEQUENCE_REPLACEMENTS
	}
	after.update(
		{
			target_name.removesuffix(".png"): read_rgba(PROJECTILE_ROOT / target_name)
			for target_name in PROJECTILE_REPLACEMENTS
		}
	)
	if not CONTACT_PATH.exists():
		build_contact_sheet(before, after)
	else:
		refresh_contact_after_panes(after)
	update_index()
	print(f"Repaired {len(SEQUENCE_REPLACEMENTS)} sequences and {len(PROJECTILE_REPLACEMENTS)} projectiles")
	print(f"Manifest: {MANIFEST_PATH.relative_to(ROOT)}")
	print(f"Contact sheet: {CONTACT_PATH.relative_to(ROOT)}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
