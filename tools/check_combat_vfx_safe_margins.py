#!/usr/bin/env python3
"""Reject combat VFX frames that can look cropped under runtime filtering."""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SEQUENCE_ROOT = ROOT / "assets/production/sprites/vfx_sequences"
MIN_MARGIN_RATIO = 0.075
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


def _referenced_frames(sequence_dir: Path) -> list[Path]:
	metadata_files = sorted(sequence_dir.glob("*_sequence.json"))
	if not metadata_files:
		return sorted(sequence_dir.glob("*.png"))
	metadata = json.loads(metadata_files[0].read_text())
	return [
		ROOT / "assets/production" / str(relative)
		for relative in metadata.get("frames", [])
	]


def main() -> int:
	failures: list[str] = []
	checked_frames = 0
	checked_sequences = 0
	for sequence_dir in sorted(path for path in SEQUENCE_ROOT.iterdir() if path.is_dir()):
		if not sequence_dir.name.startswith(SEQUENCE_PREFIXES):
			continue
		frames = _referenced_frames(sequence_dir)
		if not frames:
			continue
		checked_sequences += 1
		for frame in frames:
			if not frame.exists():
				failures.append(f"{frame.relative_to(ROOT)}: referenced frame is missing")
				continue
			with Image.open(frame) as source:
				image = source.convert("RGBA")
			bbox = image.getchannel("A").getbbox()
			if bbox is None:
				# Deliberate blank bookend frames are valid animation timing.
				continue
			checked_frames += 1
			width, height = image.size
			required = int(math.floor(min(width, height) * MIN_MARGIN_RATIO))
			margin = min(
				bbox[0],
				bbox[1],
				width - bbox[2],
				height - bbox[3],
			)
			if margin < required:
				failures.append(
					f"{frame.relative_to(ROOT)}: margin={margin}px required={required}px bbox={bbox}"
				)
	if failures:
		print(
			f"Combat VFX safe-margin check FAILED: "
			f"{len(failures)} frame(s) below {MIN_MARGIN_RATIO:.1%}"
		)
		for failure in failures:
			print(f"  - {failure}")
		return 1
	print(
		f"Combat VFX safe-margin check passed: "
		f"{checked_frames} non-empty frames across {checked_sequences} sequences"
	)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
