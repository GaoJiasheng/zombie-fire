#!/usr/bin/env python3
"""Integrate the owner-approved premium combat VFX atlases.

The generated atlases are deliberately padded. This script keeps that padding
through every runtime frame and fails if visible pixels enter the outer 12% of
any exported image.
"""

from __future__ import annotations

import json
import math
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
SOURCE = PROD / "source_refs" / "generated" / "premium_combat_vfx_2026_07_26"
VFX = PROD / "sprites" / "vfx"
PREMIUM_VFX = VFX / "premium"
SEQUENCES = PROD / "sprites" / "vfx_sequences"
PROJECTILES = PROD / "sprites" / "projectiles"
CONTACT = PROD / "contact_sheets" / "premium_combat_vfx_2026_07_26.png"
MANIFEST = SOURCE / "premium_combat_vfx_manifest.json"


@dataclass(frozen=True)
class CellSpec:
	sequence_id: str
	still_path: Path
	size: int
	frames: int
	fps: int
	fit: float = 0.54


BOSS_ATTACKS = [
	CellSpec("vfx_boss_attack_titan", PREMIUM_VFX / "vfx_boss_attack_titan.png", 768, 14, 22),
	CellSpec("vfx_boss_attack_inferno", PREMIUM_VFX / "vfx_boss_attack_inferno.png", 768, 14, 22),
	CellSpec("vfx_boss_attack_frost", PREMIUM_VFX / "vfx_boss_attack_frost.png", 768, 14, 22),
	CellSpec("vfx_boss_attack_storm", PREMIUM_VFX / "vfx_boss_attack_storm.png", 768, 14, 24),
	CellSpec("vfx_boss_attack_plague", PREMIUM_VFX / "vfx_boss_attack_plague.png", 768, 14, 22),
	CellSpec("vfx_boss_attack_void", PREMIUM_VFX / "vfx_boss_attack_void.png", 768, 14, 24),
	CellSpec("vfx_boss_attack_necro", PREMIUM_VFX / "vfx_boss_attack_necro.png", 768, 14, 22),
	CellSpec("vfx_boss_attack_apex", PREMIUM_VFX / "vfx_boss_attack_apex.png", 768, 14, 24),
]

BOSS_SKILLS = [
	CellSpec("vfx_enemy_skill_armor_break", PREMIUM_VFX / "vfx_boss_skill_armor_break.png", 640, 14, 22),
	CellSpec("vfx_enemy_skill_phase_burn", PREMIUM_VFX / "vfx_boss_skill_phase_burn.png", 640, 14, 22),
	CellSpec("vfx_enemy_skill_freeze_field", PREMIUM_VFX / "vfx_boss_skill_freeze_field.png", 640, 14, 22),
	CellSpec("vfx_enemy_skill_storm_chain", PREMIUM_VFX / "vfx_boss_skill_storm_chain.png", 640, 14, 24),
	CellSpec("vfx_enemy_skill_spawn_minions", PREMIUM_VFX / "vfx_boss_skill_spawn_minions.png", 640, 14, 22),
	CellSpec("vfx_enemy_skill_phase_shift", PREMIUM_VFX / "vfx_boss_skill_phase_shift.png", 640, 14, 24),
	CellSpec("vfx_enemy_skill_regenerate", PREMIUM_VFX / "vfx_boss_skill_regenerate.png", 640, 14, 22),
	CellSpec("vfx_enemy_skill_multi_phase", PREMIUM_VFX / "vfx_boss_skill_multi_phase.png", 640, 14, 24),
]

CHARACTER_ACTIVES = [
	CellSpec(
		"vfx_active_sig_vanguard_railvolley",
		PREMIUM_VFX / "vfx_active_sig_vanguard_railvolley.png",
		768,
		14,
		22,
	),
	CellSpec(
		"vfx_active_sig_blaze_meltdown",
		PREMIUM_VFX / "vfx_active_sig_blaze_meltdown.png",
		768,
		14,
		22,
	),
	CellSpec(
		"vfx_active_sig_frost_glacier",
		PREMIUM_VFX / "vfx_active_sig_frost_glacier.png",
		768,
		14,
		22,
	),
	CellSpec(
		"vfx_active_sig_volt_storm",
		PREMIUM_VFX / "vfx_active_sig_volt_storm.png",
		768,
		14,
		24,
	),
]

HIT_EFFECTS = [
	CellSpec("vfx_hit_physical", VFX / "vfx_hit_physical.png", 512, 12, 26, 0.48),
	CellSpec("vfx_crit", VFX / "vfx_crit.png", 512, 12, 26, 0.5),
	CellSpec("vfx_hit_fire", VFX / "vfx_hit_fire.png", 512, 12, 26, 0.5),
	CellSpec("vfx_hit_ice", VFX / "vfx_hit_ice.png", 512, 12, 26, 0.5),
	CellSpec("vfx_hit_lightning", VFX / "vfx_hit_lightning.png", 512, 12, 28, 0.5),
	CellSpec("vfx_hit_poison", VFX / "vfx_hit_poison.png", 512, 12, 26, 0.5),
	CellSpec("vfx_hit_armor", PREMIUM_VFX / "vfx_hit_armor.png", 512, 12, 26, 0.5),
	CellSpec("vfx_hit_immune", VFX / "vfx_hit_immune.png", 512, 12, 26, 0.5),
	CellSpec("vfx_hit_weak", PREMIUM_VFX / "vfx_hit_weak.png", 512, 12, 28, 0.5),
]

DEATH_EFFECTS = [
	CellSpec("vfx_death_physical", PREMIUM_VFX / "vfx_death_physical.png", 640, 14, 22),
	CellSpec("vfx_death_fire", PREMIUM_VFX / "vfx_death_fire.png", 640, 14, 22),
	CellSpec("vfx_death_ice", PREMIUM_VFX / "vfx_death_ice.png", 640, 14, 22),
	CellSpec("vfx_death_energy", PREMIUM_VFX / "vfx_death_energy.png", 640, 14, 22),
]

PROJECTILE_OUTPUTS = [
	PROJECTILES / "proj_bullet_physical.png",
	PROJECTILES / "proj_bullet_fire.png",
	PROJECTILES / "proj_bullet_ice.png",
	PROJECTILES / "proj_bullet_lightning.png",
	PROJECTILES / "proj_bullet_poison.png",
	PROJECTILES / "proj_rail_slug.png",
	PROJECTILES / "proj_scatter_pellet.png",
	PROJECTILES / "proj_plasma_orb.png",
]

GLOBAL_EFFECT_ALIASES = {
	"boss_attacks_padded_alpha.png": {
		1: CellSpec("vfx_explosion_fire", VFX / "vfx_explosion_fire.png", 512, 16, 22, 0.52),
		2: CellSpec("vfx_freeze", VFX / "vfx_freeze.png", 512, 12, 22, 0.52),
		4: CellSpec("vfx_poison_cloud", VFX / "vfx_poison_cloud.png", 512, 12, 22, 0.5),
	},
	"boss_skills_padded_alpha.png": {
		3: CellSpec("vfx_chain_lightning", VFX / "vfx_chain_lightning.png", 640, 14, 26, 0.5),
	},
}

MUZZLE_EFFECTS = [
	CellSpec("vfx_muzzle_physical", VFX / "vfx_muzzle_physical.png", 512, 8, 28, 0.46),
	CellSpec("vfx_muzzle_fire", VFX / "vfx_muzzle_fire.png", 512, 8, 28, 0.46),
	CellSpec("vfx_muzzle_ice", VFX / "vfx_muzzle_ice.png", 512, 8, 28, 0.46),
	CellSpec("vfx_muzzle_lightning", VFX / "vfx_muzzle_lightning.png", 512, 8, 30, 0.46),
	CellSpec("vfx_muzzle_poison", VFX / "vfx_muzzle_poison.png", 512, 8, 28, 0.46),
]


def alpha_bbox(image: Image.Image, threshold: int = 5) -> tuple[int, int, int, int]:
	alpha = image.getchannel("A").point(lambda value: 255 if value > threshold else 0)
	return alpha.getbbox() or (0, 0, image.width, image.height)


def clean_alpha(image: Image.Image, floor: int = 5) -> Image.Image:
	out = image.convert("RGBA")
	alpha = out.getchannel("A").point(
		lambda value: 0 if value <= floor else int(255 * ((value - floor) / (255 - floor)) ** 0.9)
	)
	out.putalpha(alpha)
	return out


def crop_grid(image: Image.Image, cols: int, rows: int) -> list[Image.Image]:
	cells: list[Image.Image] = []
	for row in range(rows):
		for col in range(cols):
			x0 = round(col * image.width / cols)
			x1 = round((col + 1) * image.width / cols)
			y0 = round(row * image.height / rows)
			y1 = round((row + 1) * image.height / rows)
			cells.append(clean_alpha(image.crop((x0, y0, x1, y1))))
	return cells


def normalize_square(image: Image.Image, target: int, fit: float) -> Image.Image:
	content = image.crop(alpha_bbox(image))
	scale = min(target * fit / max(1, content.width), target * fit / max(1, content.height))
	new_size = (
		max(1, round(content.width * scale)),
		max(1, round(content.height * scale)),
	)
	content = content.resize(new_size, Image.Resampling.LANCZOS)
	content = ImageEnhance.Sharpness(content).enhance(1.12)
	content = ImageEnhance.Contrast(content).enhance(1.035)
	canvas = Image.new("RGBA", (target, target), (0, 0, 0, 0))
	canvas.alpha_composite(content, ((target - content.width) // 2, (target - content.height) // 2))
	return clean_alpha(canvas, 3)


def normalize_projectile(image: Image.Image, target: int = 256) -> Image.Image:
	content = image.crop(alpha_bbox(image))
	scale = min(target * 0.72 / max(1, content.width), target * 0.42 / max(1, content.height))
	new_size = (
		max(1, round(content.width * scale)),
		max(1, round(content.height * scale)),
	)
	content = content.resize(new_size, Image.Resampling.LANCZOS)
	content = ImageEnhance.Sharpness(content).enhance(1.18)
	canvas = Image.new("RGBA", (target, target), (0, 0, 0, 0))
	canvas.alpha_composite(content, ((target - content.width) // 2, (target - content.height) // 2))
	return clean_alpha(canvas, 3)


def render_animation_frame(base: Image.Image, progress: float) -> Image.Image:
	if progress < 0.22:
		phase = progress / 0.22
		scale = 0.46 + 0.54 * math.sin(phase * math.pi * 0.5)
		alpha = phase
	elif progress < 0.58:
		phase = (progress - 0.22) / 0.36
		scale = 1.0 + 0.07 * math.sin(phase * math.pi)
		alpha = 1.0
	else:
		phase = (progress - 0.58) / 0.42
		scale = 1.0 + 0.12 * phase
		alpha = max(0.0, 1.0 - phase**1.35)
	new_size = (
		max(1, round(base.width * scale)),
		max(1, round(base.height * scale)),
	)
	scaled = base.resize(new_size, Image.Resampling.LANCZOS)
	if progress > 0.8:
		scaled = scaled.filter(ImageFilter.GaussianBlur((progress - 0.8) * 2.2))
	scaled.putalpha(scaled.getchannel("A").point(lambda value: round(value * alpha)))
	canvas = Image.new("RGBA", base.size, (0, 0, 0, 0))
	canvas.alpha_composite(scaled, ((base.width - scaled.width) // 2, (base.height - scaled.height) // 2))
	return clean_alpha(canvas, 2)


def write_sequence(spec: CellSpec, cell: Image.Image, source_name: str) -> list[Path]:
	base = normalize_square(cell, spec.size, spec.fit)
	spec.still_path.parent.mkdir(parents=True, exist_ok=True)
	base.save(spec.still_path)
	out_dir = SEQUENCES / spec.sequence_id
	out_dir.mkdir(parents=True, exist_ok=True)
	frames: list[Path] = []
	frame_refs: list[str] = []
	for index in range(spec.frames):
		progress = index / max(1, spec.frames - 1)
		frame = render_animation_frame(base, progress)
		out_path = out_dir / f"{spec.sequence_id}_{index + 1:02d}.png"
		frame.save(out_path)
		frames.append(out_path)
		frame_refs.append(str(out_path.relative_to(PROD)))
	sequence = {
		"id": spec.sequence_id,
		"fps": spec.fps,
		"frames": frame_refs,
		"source": f"assets/production/source_refs/generated/premium_combat_vfx_2026_07_26/{source_name}",
		"integration": (
			"Owner-directed premium AI-rendered VFX; chroma-key alpha extraction, "
			"centered safe-zone normalization, and bounded PNG frame animation."
		),
	}
	(out_dir / f"{spec.sequence_id}_sequence.json").write_text(
		json.dumps(sequence, ensure_ascii=False, indent=2) + "\n"
	)
	return [spec.still_path, *frames, out_dir / f"{spec.sequence_id}_sequence.json"]


def write_group(
	atlas_name: str,
	cols: int,
	rows: int,
	specs: list[CellSpec],
) -> list[Path]:
	atlas_path = SOURCE / atlas_name
	atlas = Image.open(atlas_path).convert("RGBA")
	cells = crop_grid(atlas, cols, rows)
	if len(cells) != len(specs):
		raise RuntimeError(f"{atlas_name}: {len(cells)} cells for {len(specs)} specs")
	written: list[Path] = []
	for spec, cell in zip(specs, cells):
		written.extend(write_sequence(spec, cell, atlas_name))
	return written


def write_projectiles() -> list[Path]:
	atlas_name = "weapon_projectiles_padded_alpha.png"
	atlas = Image.open(SOURCE / atlas_name).convert("RGBA")
	cells = crop_grid(atlas, 4, 2)
	written: list[Path] = []
	for cell, out_path in zip(cells, PROJECTILE_OUTPUTS):
		out_path.parent.mkdir(parents=True, exist_ok=True)
		normalize_projectile(cell).save(out_path)
		written.append(out_path)
	return written


def write_global_aliases() -> list[Path]:
	written: list[Path] = []
	for atlas_name, aliases in GLOBAL_EFFECT_ALIASES.items():
		atlas = Image.open(SOURCE / atlas_name).convert("RGBA")
		cells = crop_grid(atlas, 4, 2)
		for cell_index, spec in aliases.items():
			written.extend(write_sequence(spec, cells[cell_index], atlas_name))
	projectile_atlas_name = "weapon_projectiles_padded_alpha.png"
	projectile_atlas = Image.open(SOURCE / projectile_atlas_name).convert("RGBA")
	projectile_cells = crop_grid(projectile_atlas, 4, 2)
	for spec, cell in zip(MUZZLE_EFFECTS, projectile_cells[: len(MUZZLE_EFFECTS)]):
		written.extend(write_sequence(spec, cell, projectile_atlas_name))
	return written


def assert_safe_zone(path: Path, margin_ratio: float = 0.12) -> None:
	image = Image.open(path).convert("RGBA")
	alpha = image.getchannel("A")
	margin_x = max(1, round(image.width * margin_ratio))
	margin_y = max(1, round(image.height * margin_ratio))
	inner = Image.new("L", image.size, 0)
	inner.paste(255, (margin_x, margin_y, image.width - margin_x, image.height - margin_y))
	outside = ImageChops.multiply(alpha, ImageChops.invert(inner))
	if outside.getbbox() is not None:
		raise RuntimeError(f"unsafe alpha enters outer {margin_ratio:.0%}: {path.relative_to(ROOT)}")


def make_contact_sheet(stills: list[Path]) -> None:
	cell_w, cell_h = 220, 184
	cols = 5
	rows = math.ceil(len(stills) / cols)
	sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (8, 12, 18, 255))
	for index, path in enumerate(stills):
		image = Image.open(path).convert("RGBA")
		image.thumbnail((176, 134), Image.Resampling.LANCZOS)
		x = (index % cols) * cell_w + (cell_w - image.width) // 2
		y = (index // cols) * cell_h + 8 + (134 - image.height) // 2
		sheet.alpha_composite(image, (x, y))
	CONTACT.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(CONTACT)


def main() -> int:
	PREMIUM_VFX.mkdir(parents=True, exist_ok=True)
	written: list[Path] = []
	written += write_group("boss_attacks_padded_alpha.png", 4, 2, BOSS_ATTACKS)
	written += write_group("boss_skills_padded_alpha.png", 4, 2, BOSS_SKILLS)
	written += write_group("character_actives_padded_alpha.png", 2, 2, CHARACTER_ACTIVES)
	written += write_group("zombie_hits_padded_alpha.png", 3, 3, HIT_EFFECTS)
	written += write_group("zombie_deaths_padded_alpha.png", 2, 2, DEATH_EFFECTS)
	written += write_projectiles()
	written += write_global_aliases()

	# Keep the long-standing static death path aligned with the new kinetic death art.
	shutil.copy2(PREMIUM_VFX / "vfx_death_physical.png", VFX / "vfx_death_dissolve.png")
	written.append(VFX / "vfx_death_dissolve.png")

	runtime_pngs = sorted({path for path in written if path.suffix == ".png"})
	for path in runtime_pngs:
		assert_safe_zone(path)
	make_contact_sheet(
		[
			*(spec.still_path for spec in BOSS_ATTACKS),
			*(spec.still_path for spec in BOSS_SKILLS),
			*(spec.still_path for spec in CHARACTER_ACTIVES),
			*PROJECTILE_OUTPUTS,
			*(spec.still_path for spec in HIT_EFFECTS),
			*(spec.still_path for spec in DEATH_EFFECTS),
			*(spec.still_path for spec in MUZZLE_EFFECTS),
		]
	)

	manifest = {
		"id": "premium_combat_vfx_2026_07_26",
		"quality_reference": "assets/production/sprites/vfx/vfx_boss_storm_column.png",
		"source_mode": "built-in image generation with owner-approved lightning-column style reference",
		"scope": {
			"boss_attacks": [spec.sequence_id for spec in BOSS_ATTACKS],
			"boss_skills": [spec.sequence_id for spec in BOSS_SKILLS],
			"character_actives": [spec.sequence_id for spec in CHARACTER_ACTIVES],
			"weapon_projectiles": [str(path.relative_to(PROD)) for path in PROJECTILE_OUTPUTS],
			"zombie_hits": [spec.sequence_id for spec in HIT_EFFECTS],
			"zombie_deaths": [spec.sequence_id for spec in DEATH_EFFECTS],
			"global_effect_aliases": [
				spec.sequence_id
				for aliases in GLOBAL_EFFECT_ALIASES.values()
				for spec in aliases.values()
			],
			"weapon_muzzles": [spec.sequence_id for spec in MUZZLE_EFFECTS],
		},
		"safety": {
			"generated_safe_margin": "at least 21% per source cell",
			"runtime_alpha_guard": "outer 12% must remain fully transparent",
			"cropping_policy": "fail integration if any runtime PNG violates the guard",
		},
		"contact_sheet": str(CONTACT.relative_to(ROOT)),
	}
	MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
	print(f"Premium combat VFX integrated: {len(runtime_pngs)} runtime PNGs")
	print(f"Contact sheet: {CONTACT.relative_to(ROOT)}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
