#!/usr/bin/env python3
"""Validate combat VFX as gameplay communication, not only as PNG files.

This gate complements the safe-margin check. It verifies sequence integrity,
rejects the characteristic "cropped atlas cell padded inside a larger canvas"
failure, records every directional texture's source-forward contract, and
checks that runtime code rotates movement/projectile art onto real travel
vectors.
"""

from __future__ import annotations

import hashlib
import json
import math
import re
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SEQUENCE_ROOT = ROOT / "assets/production/sprites/vfx_sequences"
CONTRACT_PATH = ROOT / "design/assets/combat_vfx_semantic_contracts.json"
BATTLE_PATH = ROOT / "gameplay/battle/battle.gd"
PROJECTILE_PATH = ROOT / "gameplay/projectile/projectile.gd"

DEFAULT_MARGIN_RATIO = 0.075
GRAPHIC_BAND_MARGIN_RATIO = 0.015
PROJECTILE_MARGIN_RATIO = 0.05
ALPHA_THRESHOLD = 12
HARD_EDGE_COVERAGE = 0.14
HARD_EDGE_CONTIGUOUS = 0.10


def load_json(path: Path) -> dict:
	return json.loads(path.read_text(encoding="utf-8"))


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
	mask = image.getchannel("A").point(lambda value: 255 if value > ALPHA_THRESHOLD else 0)
	return mask.getbbox()


def longest_run(values: list[int]) -> int:
	best = 0
	run = 0
	for value in values:
		run = run + 1 if value else 0
		best = max(best, run)
	return best


def hard_edge_signature(image: Image.Image) -> tuple[str, float, float] | None:
	mask = image.getchannel("A").point(lambda value: 255 if value > ALPHA_THRESHOLD else 0)
	bbox = mask.getbbox()
	if bbox is None:
		return None
	x0, y0, x1, y1 = bbox
	pixels = mask.load()
	sides = [
		("left", [1 if pixels[x0, y] else 0 for y in range(y0, y1)]),
		("right", [1 if pixels[x1 - 1, y] else 0 for y in range(y0, y1)]),
		("top", [1 if pixels[x, y0] else 0 for x in range(x0, x1)]),
		("bottom", [1 if pixels[x, y1 - 1] else 0 for x in range(x0, x1)]),
	]
	for side, values in sides:
		if not values:
			continue
		coverage = sum(values) / len(values)
		contiguous = longest_run(values) / len(values)
		if coverage > HARD_EDGE_COVERAGE or contiguous > HARD_EDGE_CONTIGUOUS:
			return side, coverage, contiguous
	return None


def referenced_frames(sequence_dir: Path) -> tuple[Path, dict, list[Path]]:
	metadata_files = sorted(sequence_dir.glob("*_sequence.json"))
	if len(metadata_files) != 1:
		raise ValueError(f"expected exactly one sequence JSON, found {len(metadata_files)}")
	metadata_path = metadata_files[0]
	metadata = load_json(metadata_path)
	frames = [
		ROOT / "assets/production" / str(relative)
		for relative in metadata.get("frames", [])
	]
	return metadata_path, metadata, frames


def parse_directional_runtime_contract(source: str) -> dict[str, float]:
	match = re.search(
		r"const DIRECTIONAL_VFX_SOURCE_FORWARD := \{(?P<body>.*?)\n\}",
		source,
		re.DOTALL,
	)
	if match is None:
		return {}
	result: dict[str, float] = {}
	for sequence_id, value in re.findall(r'"([^"]+)"\s*:\s*([-+0-9.eE]+)', match.group("body")):
		result[sequence_id] = float(value)
	return result


def check_sequence_integrity(contract: dict, failures: list[str]) -> tuple[int, int]:
	exceptions = contract.get("hard_edge_exceptions", {})
	checked_sequences = 0
	checked_frames = 0
	for sequence_dir in sorted(path for path in SEQUENCE_ROOT.iterdir() if path.is_dir()):
		checked_sequences += 1
		try:
			metadata_path, metadata, frames = referenced_frames(sequence_dir)
		except (ValueError, json.JSONDecodeError) as exc:
			failures.append(f"{sequence_dir.relative_to(ROOT)}: {exc}")
			continue
		sequence_id = sequence_dir.name
		if str(metadata.get("id", "")) != sequence_id:
			failures.append(
				f"{metadata_path.relative_to(ROOT)}: id={metadata.get('id')} must match {sequence_id}"
			)
		if not 1 <= float(metadata.get("fps", 0.0)) <= 60:
			failures.append(f"{metadata_path.relative_to(ROOT)}: fps must be in 1..60")
		if len(frames) < 2:
			failures.append(f"{metadata_path.relative_to(ROOT)}: needs at least two frames")
			continue
		dimensions: set[tuple[int, int]] = set()
		hashes: set[str] = set()
		non_empty: list[tuple[Path, Image.Image]] = []
		for frame in frames:
			if not frame.exists():
				failures.append(f"{frame.relative_to(ROOT)}: referenced frame is missing")
				continue
			with Image.open(frame) as source:
				image = source.convert("RGBA")
			dimensions.add(image.size)
			hashes.add(hashlib.sha256(image.tobytes()).hexdigest())
			bbox = alpha_bbox(image)
			if bbox is None:
				continue
			checked_frames += 1
			non_empty.append((frame, image))
			required_ratio = (
				GRAPHIC_BAND_MARGIN_RATIO
				if sequence_id in exceptions
				else DEFAULT_MARGIN_RATIO
			)
			required = int(math.floor(min(image.size) * required_ratio))
			margin = min(
				bbox[0],
				bbox[1],
				image.width - bbox[2],
				image.height - bbox[3],
			)
			if margin < required:
				failures.append(
					f"{frame.relative_to(ROOT)}: alpha margin={margin}px, required={required}px"
				)
		if len(dimensions) != 1:
			failures.append(
				f"{sequence_dir.relative_to(ROOT)}: frame dimension drift {sorted(dimensions)}"
			)
		if not non_empty:
			failures.append(f"{sequence_dir.relative_to(ROOT)}: all referenced frames are blank")
			continue
		if len(hashes) < max(2, len(frames) // 3):
			failures.append(
				f"{sequence_dir.relative_to(ROOT)}: insufficient frame variation "
				f"({len(hashes)} unique / {len(frames)})"
			)
		mid_path, mid_image = non_empty[len(non_empty) // 2]
		hard_edge = hard_edge_signature(mid_image)
		if hard_edge is not None and sequence_id not in exceptions:
			side, coverage, contiguous = hard_edge
			failures.append(
				f"{mid_path.relative_to(ROOT)}: probable pre-cropped atlas edge on {side} "
				f"(coverage={coverage:.1%}, contiguous={contiguous:.1%})"
			)
	return checked_sequences, checked_frames


def check_directional_contract(contract: dict, failures: list[str]) -> int:
	battle_source = BATTLE_PATH.read_text(encoding="utf-8")
	runtime_contract = parse_directional_runtime_contract(battle_source)
	expected = contract.get("directional_sequences", {})
	for sequence_id, spec in expected.items():
		if sequence_id not in runtime_contract:
			failures.append(f"{sequence_id}: missing from Battle directional runtime contract")
			continue
		expected_rad = math.radians(float(spec.get("source_forward_degrees", 0.0)))
		if abs(runtime_contract[sequence_id] - expected_rad) > 0.001:
			failures.append(
				f"{sequence_id}: runtime source-forward={runtime_contract[sequence_id]:.6f}rad "
				f"expected={expected_rad:.6f}rad"
			)
		sequence_dir = SEQUENCE_ROOT / sequence_id
		if not sequence_dir.is_dir():
			failures.append(f"{sequence_id}: directional sequence directory is missing")
	required_runtime_snippets = [
		"travel_direction: Vector2 = source.global_position - old_position",
		"_spawn_enemy_attack_vfx(source, kind, source.global_position + Vector2(0, -36.0), travel_direction)",
		'_spawn_enemy_attack_vfx(source, "phase_shift", source.global_position, source.global_position - old_position)',
		"var rotation := _directional_vfx_rotation(",
		"target - origin,",
	]
	for snippet in required_runtime_snippets:
		if snippet not in battle_source:
			failures.append(f"battle.gd: missing directional semantic wiring: {snippet}")
	return len(expected)


def check_projectiles(contract: dict, failures: list[str]) -> int:
	projectile_spec = contract.get("directional_projectiles", {})
	paths = [ROOT / str(path) for path in projectile_spec.get("paths", [])]
	projectile_source = PROJECTILE_PATH.read_text(encoding="utf-8")
	if "rotation = flight_direction.angle() - SPRITE_FORWARD_ANGLE" not in projectile_source:
		failures.append("projectile.gd: initial sprite rotation must follow the flight vector")
	if "rotation = velocity.angle() - SPRITE_FORWARD_ANGLE" not in projectile_source:
		failures.append("projectile.gd: homing sprite rotation must continue following velocity")
	battle_source = BATTLE_PATH.read_text(encoding="utf-8")
	for snippet in [
		"spit.rotation = (target_position - spit.global_position).angle()",
		"bolt.rotation = (target - origin).angle()",
	]:
		if snippet not in battle_source:
			failures.append(f"battle.gd: missing projectile direction wiring: {snippet}")
	for path in paths:
		if not path.exists():
			failures.append(f"{path.relative_to(ROOT)}: directional projectile is missing")
			continue
		with Image.open(path) as source:
			image = source.convert("RGBA")
		bbox = alpha_bbox(image)
		if bbox is None:
			failures.append(f"{path.relative_to(ROOT)}: projectile has no visible pixels")
			continue
		required = int(math.floor(min(image.size) * PROJECTILE_MARGIN_RATIO))
		margin = min(
			bbox[0],
			bbox[1],
			image.width - bbox[2],
			image.height - bbox[3],
		)
		if margin < required:
			failures.append(
				f"{path.relative_to(ROOT)}: projectile margin={margin}px, required={required}px"
			)
		content_width = bbox[2] - bbox[0]
		content_height = bbox[3] - bbox[1]
		if content_width < content_height * 1.2:
			failures.append(
				f"{path.relative_to(ROOT)}: source-forward contract requires a horizontal silhouette"
			)
	return len(paths)


def check_content_coverage(contract: dict, failures: list[str]) -> tuple[int, int, int]:
	sequence_ids = {path.name for path in SEQUENCE_ROOT.iterdir() if path.is_dir()}
	bosses = load_json(ROOT / "data/bosses.json")
	characters = load_json(ROOT / "data/characters.json")
	skills = load_json(ROOT / "data/skills.json")
	boss_profiles = 0
	for boss_id, boss in bosses.items():
		profile = boss.get("mechanic_params", {}).get("base_attack_profile", {})
		if not profile:
			failures.append(f"{boss_id}: missing data-driven base_attack_profile")
			continue
		boss_profiles += 1
		for key in ("cast_sequence", "impact_sequence"):
			sequence_id = str(profile.get(key, ""))
			if sequence_id not in sequence_ids:
				failures.append(f"{boss_id}: {key}={sequence_id} has no runtime sequence")
	active_count = 0
	for character_id, character in characters.items():
		active_id = str(character.get("active_skill", {}).get("id", ""))
		sequence_id = f"vfx_active_{active_id}"
		if sequence_id not in sequence_ids:
			failures.append(f"{character_id}: active VFX sequence is missing: {sequence_id}")
		else:
			active_count += 1
	skill_count = 0
	for skill_id in skills:
		sequence_id = f"vfx_skill_cast_{skill_id.removeprefix('skill_')}"
		if sequence_id not in sequence_ids:
			failures.append(f"{skill_id}: card/cast VFX sequence is missing: {sequence_id}")
		else:
			skill_count += 1
	for group_name, spec in contract.get("semantic_groups", {}).items():
		prefix = str(spec.get("prefix", ""))
		count = sum(1 for sequence_id in sequence_ids if sequence_id.startswith(prefix))
		minimum = int(spec.get("minimum_count", 0))
		if count < minimum:
			failures.append(
				f"semantic group {group_name}: found {count} sequences with {prefix}, "
				f"required at least {minimum}"
			)
	return boss_profiles, active_count, skill_count


def check_visual_distinctness(contract: dict, failures: list[str]) -> int:
	checked = 0
	for group_name, spec in contract.get("visual_distinctness_groups", {}).items():
		hashes: set[str] = set()
		for sequence_id in spec.get("sequence_ids", []):
			sequence_dir = SEQUENCE_ROOT / str(sequence_id)
			if not sequence_dir.is_dir():
				failures.append(f"visual distinctness {group_name}: missing {sequence_id}")
				continue
			try:
				_, _, frames = referenced_frames(sequence_dir)
			except (ValueError, json.JSONDecodeError) as exc:
				failures.append(f"visual distinctness {group_name}/{sequence_id}: {exc}")
				continue
			if not frames:
				failures.append(f"visual distinctness {group_name}: {sequence_id} has no frames")
				continue
			with Image.open(frames[len(frames) // 2]) as source:
				image = source.convert("RGBA")
			signature_image = image.resize((128, 128), Image.Resampling.LANCZOS)
			hashes.add(hashlib.sha256(signature_image.tobytes()).hexdigest())
		minimum = int(spec.get("minimum_unique_mid_frames", 0))
		if len(hashes) < minimum:
			failures.append(
				f"visual distinctness {group_name}: {len(hashes)} unique mid-frame silhouettes, "
				f"required {minimum}"
			)
		checked += 1
	return checked


def main() -> int:
	failures: list[str] = []
	if not CONTRACT_PATH.exists():
		print(f"Combat VFX semantic check FAILED: missing {CONTRACT_PATH.relative_to(ROOT)}")
		return 1
	contract = load_json(CONTRACT_PATH)
	sequence_count, frame_count = check_sequence_integrity(contract, failures)
	directional_count = check_directional_contract(contract, failures)
	projectile_count = check_projectiles(contract, failures)
	boss_count, active_count, skill_count = check_content_coverage(contract, failures)
	distinctness_count = check_visual_distinctness(contract, failures)
	if failures:
		print(f"Combat VFX semantic check FAILED: {len(failures)} issue(s)")
		for failure in failures:
			print(f"  - {failure}")
		return 1
	print(
		"Combat VFX semantic check passed: "
		f"{sequence_count} sequences / {frame_count} non-empty frames / "
		f"{directional_count} movement contracts / {projectile_count} projectiles / "
		f"{boss_count} boss attack profiles / {active_count} actives / {skill_count} card casts"
		f" / {distinctness_count} visual distinctness groups"
	)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
