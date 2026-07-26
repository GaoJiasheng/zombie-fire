#!/usr/bin/env python3
"""Refit legacy combat VFX sequences into a safe transparent canvas.

The premium 2026-07-26 renders already reserve generous source margins. Older
card-cast and zombie-skill sequences were authored much closer to the edge,
which lets additive filtering make them look visibly cropped in motion. This
tool keeps every frame, duration, ID, and runtime path unchanged; it applies one
consistent center-preserving scale per affected sequence so animation motion
does not pop between frames.
"""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SEQUENCE_ROOT = ROOT / "assets/production/sprites/vfx_sequences"
REPORT_PATH = (
	ROOT
	/ "assets/production/source_refs/generated/premium_combat_vfx_2026_07_26"
	/ "legacy_sequence_safe_margin_report.json"
)
TARGET_MARGIN_RATIO = 0.10
SEQUENCE_PREFIXES = (
	"vfx_active_",
	"vfx_boss_attack_",
	"vfx_chain_lightning",
	"vfx_crit",
	"vfx_death_",
	"vfx_enemy_skill_",
	"vfx_explosion_fire",
	"vfx_freeze",
	"vfx_hit_",
	"vfx_muzzle_",
	"vfx_poison_cloud",
	"vfx_skill_cast_",
)


def _sha256(path: Path) -> str:
	digest = hashlib.sha256()
	with path.open("rb") as handle:
		for chunk in iter(lambda: handle.read(1024 * 1024), b""):
			digest.update(chunk)
	return digest.hexdigest()


def _union_bbox(frames: list[Path]) -> tuple[int, int, int, int] | None:
	union: tuple[int, int, int, int] | None = None
	for frame in frames:
		with Image.open(frame) as image:
			bbox = image.convert("RGBA").getchannel("A").getbbox()
		if bbox is None:
			continue
		if union is None:
			union = bbox
		else:
			union = (
				min(union[0], bbox[0]),
				min(union[1], bbox[1]),
				max(union[2], bbox[2]),
				max(union[3], bbox[3]),
			)
	return union


def _referenced_frames(sequence_dir: Path) -> list[Path]:
	metadata_files = sorted(sequence_dir.glob("*_sequence.json"))
	if not metadata_files:
		return sorted(sequence_dir.glob("*.png"))
	metadata = json.loads(metadata_files[0].read_text())
	frames: list[Path] = []
	for relative in metadata.get("frames", []):
		path = ROOT / "assets/production" / str(relative)
		if not path.exists():
			raise FileNotFoundError(
				f"Missing referenced frame for {sequence_dir.relative_to(ROOT)}: {path.relative_to(ROOT)}"
			)
		frames.append(path)
	return frames


def _max_centered_scale(
	bbox: tuple[int, int, int, int],
	width: int,
	height: int,
	margin: int,
) -> float:
	center_x = width * 0.5
	center_y = height * 0.5
	limits = [1.0]
	left, top, right, bottom = bbox
	if left < center_x:
		limits.append((center_x - margin) / (center_x - left))
	if right > center_x:
		limits.append((width - margin - center_x) / (right - center_x))
	if top < center_y:
		limits.append((center_y - margin) / (center_y - top))
	if bottom > center_y:
		limits.append((height - margin - center_y) / (bottom - center_y))
	return max(0.1, min(limits))


def _refit_frame(path: Path, scale: float) -> None:
	with Image.open(path) as source:
		image = source.convert("RGBA")
	width, height = image.size
	new_size = (
		max(1, int(round(width * scale))),
		max(1, int(round(height * scale))),
	)
	resized = image.resize(new_size, Image.Resampling.LANCZOS)
	canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
	offset = ((width - new_size[0]) // 2, (height - new_size[1]) // 2)
	canvas.alpha_composite(resized, offset)
	canvas.save(path, optimize=True)


def main() -> int:
	changed: list[dict[str, object]] = []
	checked_sequences = 0
	for sequence_dir in sorted(path for path in SEQUENCE_ROOT.iterdir() if path.is_dir()):
		if not sequence_dir.name.startswith(SEQUENCE_PREFIXES):
			continue
		frames = _referenced_frames(sequence_dir)
		if not frames:
			continue
		checked_sequences += 1
		with Image.open(frames[0]) as first:
			width, height = first.size
		for frame in frames[1:]:
			with Image.open(frame) as image:
				if image.size != (width, height):
					raise RuntimeError(f"Mixed referenced frame sizes in {sequence_dir.relative_to(ROOT)}")
		bbox = _union_bbox(frames)
		if bbox is None:
			continue
		margin = int(math.ceil(min(width, height) * TARGET_MARGIN_RATIO))
		scale = _max_centered_scale(bbox, width, height, margin)
		if scale >= 0.999:
			continue
		before_hashes = {frame.name: _sha256(frame) for frame in frames}
		for frame in frames:
			_refit_frame(frame, scale)
		after_bbox = _union_bbox(frames)
		if after_bbox is None:
			raise RuntimeError(f"Refit unexpectedly erased {sequence_dir.relative_to(ROOT)}")
		actual_margin = min(
			after_bbox[0],
			after_bbox[1],
			width - after_bbox[2],
			height - after_bbox[3],
		)
		# Lanczos can introduce a 1–4 px low-alpha fringe outside the geometric
		# destination rectangle. Keep a small tolerance here; the persistent
		# validator below still enforces a stricter-than-runtime 7.5% clear zone.
		if actual_margin < margin - 5:
			raise RuntimeError(
				f"Safe-margin refit failed for {sequence_dir.relative_to(ROOT)}: "
				f"{actual_margin}px < {margin - 5}px"
			)
		changed.append(
			{
				"sequence": sequence_dir.name,
				"frame_count": len(frames),
				"canvas": [width, height],
				"scale": round(scale, 6),
				"before_union_bbox": list(bbox),
				"after_union_bbox": list(after_bbox),
				"after_margin_px": actual_margin,
				"before_sha256": before_hashes,
				"after_sha256": {frame.name: _sha256(frame) for frame in frames},
			}
		)

	report = {
		"generated_at": "2026-07-26",
		"purpose": "Owner-directed removal of visibly cropped combat skill VFX.",
		"operation": (
			"Center-preserving whole-canvas Lanczos refit with one scale per sequence; "
			"runtime IDs, paths, frame counts, FPS metadata, and timing remain unchanged."
		),
		"target_margin_ratio": TARGET_MARGIN_RATIO,
		"checked_sequences": checked_sequences,
		"preflight_changed_sequences": [
			"vfx_active_sig_vanguard_overload",
		],
		"changed_sequences": len(changed),
		"changes": changed,
	}
	REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
	REPORT_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
	print(
		f"Combat VFX safe-margin normalization complete: "
		f"{len(changed)}/{checked_sequences} sequences changed"
	)
	print(f"Report: {REPORT_PATH.relative_to(ROOT)}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
