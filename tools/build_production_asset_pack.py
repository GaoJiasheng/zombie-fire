#!/usr/bin/env python3
from __future__ import annotations

import math
import shutil
import wave
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SAMPLES = ROOT / "assets" / "m1_visual" / "samples"
PROD = ROOT / "assets" / "production"

CHARACTERS = ["char_vanguard", "char_blaze", "char_frost", "char_volt"]
ZOMBIES = [
    "zombie_shambler", "zombie_runner", "zombie_brute", "zombie_spitter", "zombie_crawler",
    "zombie_armored", "zombie_bomber", "zombie_shielder", "zombie_hopper", "zombie_screamer",
    "zombie_juggernaut", "zombie_phantom", "zombie_necromancer", "zombie_toxic", "zombie_charger",
    "zombie_regenerator", "zombie_splitter", "zombie_warden", "zombie_mutant", "zombie_berserker",
]
BOSSES = [
    "boss_tank_titan", "boss_inferno_maw", "boss_frost_warden", "boss_storm_caller",
    "boss_plague_mother", "boss_void_phantom", "boss_necrotitan", "boss_apex_overlord",
]
WEAPONS = [
    "weapon_autocannon", "weapon_railgun", "weapon_scattergun", "weapon_flamethrower",
    "weapon_cryocannon", "weapon_teslacoil", "weapon_venomlauncher", "weapon_plasmacannon",
]
ARMORS = ["armor_kevlar", "armor_reactive", "armor_thermal", "armor_cryo", "armor_faraday", "armor_hazmat"]
CHIPS = ["chip_attack", "chip_health", "chip_crit", "chip_haste", "chip_pierce", "chip_element", "chip_greed", "chip_guardian"]
PETS = ["pet_turret_drone", "pet_fire_imp", "pet_frost_wisp", "pet_volt_orb", "pet_medic_drone", "pet_collector"]
PROJECTILES = [
    "proj_bullet_physical", "proj_bullet_fire", "proj_bullet_ice", "proj_bullet_lightning",
    "proj_bullet_poison", "proj_heavy_charge", "proj_acid_spit", "proj_split_mini",
]
VFX = [
    "vfx_hit_physical", "vfx_hit_fire", "vfx_hit_ice", "vfx_hit_lightning", "vfx_hit_poison",
    "vfx_crit", "vfx_explosion_fire", "vfx_freeze", "vfx_chain_lightning", "vfx_poison_cloud",
    "vfx_levelup_glow", "vfx_death_dissolve", "vfx_boss_phase", "vfx_muzzle_physical",
    "vfx_muzzle_fire", "vfx_muzzle_ice", "vfx_muzzle_lightning", "vfx_muzzle_poison",
    "vfx_target_lock", "vfx_threat_warning", "vfx_hit_immune",
]
BACKGROUNDS = ["bg_city_ruins", "bg_subway", "bg_military", "bg_biolab", "bg_main_menu", "bg_level_map"]
UI = [
    "ui_button_primary", "ui_button_secondary", "ui_panel", "ui_card_frame", "ui_card_frame_fire",
    "ui_card_frame_ice", "ui_card_frame_lightning", "ui_card_frame_poison", "ui_card_frame_physical",
    "ui_base_hp_bar", "ui_wave_progress", "ui_run_xp_bar", "ui_shield_bar", "ui_skill_slot",
    "ui_skill_slot_active", "ui_cd_overlay", "ui_target_strategy_nearest", "ui_target_strategy_breach",
    "ui_target_strategy_elite", "ui_target_strategy_low_hp", "ui_target_lock", "ui_card_reroll",
    "ui_card_pin", "ui_card_skip", "ui_card_tag_projectile", "ui_card_tag_element",
    "ui_card_tag_control", "ui_card_tag_economy", "ui_star_filled", "ui_star_empty",
    "icon_currency_gold", "icon_currency_xp", "icon_currency_star", "icon_talent_point",
    "icon_reroll_charge", "icon_element_physical", "icon_element_fire", "icon_element_ice",
    "icon_element_lightning", "icon_element_poison", "icon_pause", "icon_settings", "icon_lock", "icon_warning",
]
SKILLS = [
    "sig_vanguard_railvolley", "sig_vanguard_overload", "sig_blaze_napalm", "sig_blaze_meltdown",
    "sig_frost_glacier", "sig_frost_shatter", "sig_volt_chain", "sig_volt_storm",
    "skill_split_shot", "skill_pierce", "skill_ricochet", "skill_multishot", "skill_homing",
    "skill_salvo", "skill_critical", "skill_charge_shot", "skill_incendiary", "skill_cryo",
    "skill_tesla", "skill_venom", "skill_barrier", "skill_slow_field", "skill_gold_rush", "skill_recycle",
]


def ensure_dirs() -> None:
    for path in [
        "sprites/characters", "sprites/zombies", "sprites/bosses", "sprites/weapons",
        "sprites/equipment", "sprites/pets", "sprites/projectiles", "sprites/vfx",
        "sprites/ui", "sprites/backgrounds", "audio/bgm", "audio/sfx", "video",
        "contact_sheets",
    ]:
        (PROD / path).mkdir(parents=True, exist_ok=True)


def copy(src: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)


def source_for(prefix: str, suffix: str = "prototype") -> Path:
    candidates = [
        SAMPLES / f"{prefix}_{suffix}.png",
        SAMPLES / f"{prefix}_{suffix}_v2.png",
        SAMPLES / f"{prefix}.png",
    ]
    if prefix == "char_volt":
        candidates.insert(0, SAMPLES / "char_volt_prototype.png")
    for path in candidates:
        if path.exists():
            return path
    raise FileNotFoundError(prefix)


def framed_icon(src: Path, dest: Path, size: int = 256) -> None:
    subject = Image.open(src).convert("RGBA")
    bbox = subject.getbbox()
    if bbox:
        subject = subject.crop(bbox)
    subject = ImageOps.contain(subject, (int(size * 0.78), int(size * 0.78)), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(out)
    d.rounded_rectangle((8, 8, size - 8, size - 8), radius=max(12, size // 12), fill=(18, 23, 32, 245), outline=(82, 96, 120, 255), width=max(3, size // 64))
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((size * 0.2, size * 0.18, size * 0.8, size * 0.78), fill=(70, 150, 230, 36))
    out.alpha_composite(glow.filter(ImageFilter.GaussianBlur(size // 18)))
    out.alpha_composite(subject, ((size - subject.width) // 2, (size - subject.height) // 2 + size // 24))
    out.save(dest)


def portrait(src: Path, dest: Path, size=(720, 1080)) -> None:
    subject = Image.open(src).convert("RGBA")
    bbox = subject.getbbox()
    if bbox:
        subject = subject.crop(bbox)
    subject = ImageOps.contain(subject, (int(size[0] * 0.84), int(size[1] * 0.78)), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", size, (14, 18, 26, 255))
    d = ImageDraw.Draw(out)
    d.rounded_rectangle((24, 24, size[0] - 24, size[1] - 24), radius=28, fill=(18, 23, 32, 255), outline=(92, 108, 132, 255), width=6)
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((size[0] * 0.16, size[1] * 0.1, size[0] * 0.84, size[1] * 0.72), fill=(70, 150, 230, 42))
    out.alpha_composite(glow.filter(ImageFilter.GaussianBlur(48)))
    out.alpha_composite(subject, ((size[0] - subject.width) // 2, int(size[1] * 0.12)))
    out.save(dest)


def copy_unit(prefix: str, kind: str) -> None:
    src = source_for(prefix, "prototype")
    dest_dir = PROD / "sprites" / kind
    copy(src, dest_dir / f"{prefix}_prototype.png")
    portrait(src, dest_dir / f"{prefix}_portrait.png")
    framed_icon(src, dest_dir / f"{prefix}_icon.png")


def copy_visuals() -> None:
    for item in CHARACTERS:
        copy_unit(item, "characters")
    for item in ZOMBIES:
        copy_unit(item, "zombies")
    for item in BOSSES:
        copy_unit(item, "bosses")
    for item in PETS:
        copy(source_for(item, "prototype"), PROD / "sprites/pets" / f"{item}_prototype.png")
        src = source_for(item, "prototype")
        portrait(src, PROD / "sprites/pets" / f"{item}_portrait.png", (512, 512))
        framed_icon(src, PROD / "sprites/pets" / f"{item}_icon.png", 256)
    for item in WEAPONS:
        copy(SAMPLES / f"{item}_icon.png", PROD / "sprites/weapons" / f"{item}_icon.png")
        copy(SAMPLES / f"{item}_turret.png", PROD / "sprites/weapons" / f"{item}_turret.png")
    for item in ARMORS:
        copy(SAMPLES / f"{item}_icon.png", PROD / "sprites/equipment" / f"{item}_icon.png")
    for item in CHIPS:
        copy(SAMPLES / f"{item}_icon.png", PROD / "sprites/equipment" / f"{item}_icon.png")
    for item in SKILLS:
        copy(SAMPLES / f"{item}_icon.png", PROD / "sprites/ui" / f"{item}_icon.png")
    for item in PROJECTILES:
        copy(SAMPLES / f"{item}.png", PROD / "sprites/projectiles" / f"{item}.png")
    for item in VFX:
        copy(SAMPLES / f"{item}.png", PROD / "sprites/vfx" / f"{item}.png")
    for item in BACKGROUNDS:
        copy(SAMPLES / f"{item}.png", PROD / "sprites/backgrounds" / f"{item}.png")
    for item in UI:
        copy(SAMPLES / f"{item}.png", PROD / "sprites/ui" / f"{item}.png")


def tone(freq: float, t: float, sample_rate: int, wave_type: str = "sine") -> float:
    phase = 2.0 * math.pi * freq * t
    if wave_type == "square":
        return 1.0 if math.sin(phase) >= 0 else -1.0
    if wave_type == "saw":
        return 2.0 * ((freq * t) % 1.0) - 1.0
    return math.sin(phase)


def write_wav(path: Path, duration: float, fn, sample_rate: int = 44100) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    frames = bytearray()
    total = int(duration * sample_rate)
    for i in range(total):
        t = i / sample_rate
        env = min(1.0, i / max(1, int(0.02 * sample_rate))) * min(1.0, (total - i) / max(1, int(0.08 * sample_rate)))
        val = max(-1.0, min(1.0, fn(t) * env))
        sample = int(val * 32767)
        frames += sample.to_bytes(2, "little", signed=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(frames)


def make_sfx() -> None:
    sfx_dir = PROD / "audio/sfx"
    specs = {
        "sfx_ui_click": (0.08, lambda t: 0.35 * tone(950 - 2600 * t, t, 44100)),
        "sfx_ui_confirm": (0.18, lambda t: 0.32 * (tone(520, t, 44100) + 0.55 * tone(780, t, 44100))),
        "sfx_ui_card_offer": (0.42, lambda t: 0.24 * (tone(440 + 560 * t, t, 44100) + 0.4 * tone(880 + 320 * t, t, 44100))),
        "sfx_ui_card_pick": (0.28, lambda t: 0.35 * (tone(660, t, 44100) + 0.65 * tone(990, t, 44100))),
        "sfx_shot_autocannon": (0.11, lambda t: 0.55 * (tone(95 - 30 * t, t, 44100, "square") + 0.2 * tone(180, t, 44100, "saw"))),
        "sfx_hit_physical": (0.12, lambda t: 0.42 * tone(180 - 520 * t, t, 44100, "saw")),
        "sfx_enemy_death_small": (0.32, lambda t: 0.34 * (tone(220 - 180 * t, t, 44100, "saw") + 0.2 * tone(70, t, 44100))),
        "sfx_enemy_breach": (0.38, lambda t: 0.45 * (tone(120 - 80 * t, t, 44100, "square"))),
        "sfx_gold_pickup": (0.18, lambda t: 0.34 * (tone(980 + 220 * math.sin(34 * t), t, 44100) + 0.4 * tone(1480, t, 44100))),
        "sfx_level_up": (0.62, lambda t: 0.28 * (tone(440 + 520 * t, t, 44100) + 0.45 * tone(880 + 720 * t, t, 44100))),
        "sfx_victory": (0.9, lambda t: 0.30 * (tone(523, t, 44100) + tone(659, t, 44100) + 0.6 * tone(784, t, 44100))),
        "sfx_defeat": (0.9, lambda t: 0.30 * (tone(330 - 120 * t, t, 44100) + 0.5 * tone(220 - 70 * t, t, 44100))),
        "sfx_lock_target": (0.2, lambda t: 0.28 * (tone(700 + 900 * t, t, 44100, "square") + 0.4 * tone(1400, t, 44100))),
        "sfx_threat_warning": (0.42, lambda t: 0.33 * tone(560 if int(t * 12) % 2 == 0 else 320, t, 44100, "square")),
        "sfx_hit_immune": (0.22, lambda t: 0.30 * (tone(180, t, 44100, "square") + 0.35 * tone(90, t, 44100))),
    }
    for name, (duration, fn) in specs.items():
        write_wav(sfx_dir / f"{name}.wav", duration, fn)


def make_bgm() -> None:
    bgm_dir = PROD / "audio/bgm"
    specs = {
        "bgm_menu": (42, 58),
        "bgm_map": (44, 72),
        "bgm_battle_city": (49, 96),
        "bgm_battle_subway": (43, 86),
        "bgm_battle_military": (45, 104),
        "bgm_battle_biolab": (48, 92),
        "bgm_boss": (41, 118),
        "bgm_result_victory": (52, 96),
        "bgm_result_defeat": (40, 64),
    }
    for name, (root_note, bpm) in specs.items():
        duration = 16.0 if "result" not in name else 4.0
        beat = 60.0 / bpm
        def fn(t, root_note=root_note, beat=beat, name=name):
            step = int(t / beat) % 8
            bass_freq = 440.0 * 2 ** ((root_note + [0, 0, 3, 0, 5, 3, -2, 0][step] - 69) / 12)
            pulse = 0.55 if (t % beat) < beat * 0.38 else 0.18
            pad = 0.14 * tone(bass_freq * 2, t, 44100) + 0.09 * tone(bass_freq * 3, t, 44100)
            bass = 0.24 * pulse * tone(bass_freq, t, 44100, "saw")
            tick = 0.08 * tone(1800, t, 44100) if int(t / (beat / 2)) % 2 == 0 and (t % (beat / 2)) < 0.025 else 0.0
            if "boss" in name:
                bass += 0.14 * tone(55, t, 44100, "square")
            return bass + pad + tick
        write_wav(bgm_dir / f"{name}.wav", duration, fn)


def write_status() -> None:
    status = PROD / "ASSET_PACK_STATUS.md"
    status.write_text(
        """# Production Asset Pack Status

> This is the handoff-ready prototype production asset pack.
> Visuals are copied/derived from accepted M1 visual prototypes. Audio is generated as procedural placeholder material for integration and timing.

## Complete For External Development

- Character prototype/portrait/icon PNGs: complete.
- Zombie prototype/portrait/icon PNGs: complete.
- Boss prototype/portrait/icon PNGs: complete.
- Weapon icon/turret PNGs: complete.
- Armor/chip icon PNGs: complete.
- Pet prototype/portrait/icon PNGs: complete.
- Projectile PNGs: complete.
- Single-frame VFX PNGs: complete.
- Background PNGs: complete.
- UI/icon PNGs: complete.
- P0/P1 SFX placeholder WAVs: complete.
- BGM placeholder WAV loops/stingers: complete.

## replace_later

- True skeletal body parts for characters, zombies, bosses, pets, and turrets.
- Multi-frame VFX sequences.
- Final mastered BGM and SFX.
- Video/CG files.
- App Store preview video.

## Important

External development can proceed with this pack. Final production polish should replace the `replace_later` items without changing IDs, file naming, or gameplay scope.
""",
        encoding="utf-8",
    )


def main() -> None:
    ensure_dirs()
    copy_visuals()
    make_sfx()
    make_bgm()
    write_status()
    print(f"Production asset pack built at {PROD}")


if __name__ == "__main__":
    main()

