#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text()


def main() -> int:
    audio = read("core/audio/audio_manager.gd")
    battle = read("gameplay/battle/battle.gd")
    result = read("meta/result/result.gd")
    loadout = read("meta/loadout/loadout.gd")
    collection = read("meta/collection/collection.gd")
    errors: list[str] = []

    required_music_like = [
        "sig_vanguard_railvolley",
        "sig_blaze_meltdown",
        "sig_frost_glacier",
        "sig_volt_storm",
        "victory",
        "defeat",
    ]
    if "const MUSIC_LIKE_SFX" not in audio:
        errors.append("AudioManager must define MUSIC_LIKE_SFX for long cue mutexing")
    for cue in required_music_like:
        if f'"{cue}": true' not in audio:
            errors.append(f"music-like cue missing from mutex list: {cue}")

    for required in [
        "_stop_music_like_sfx()",
        'player.set_meta("audio_id", id)',
        'player.set_meta("music_like", MUSIC_LIKE_SFX.has(id))',
        '"sig_vanguard_railvolley", "sig_blaze_meltdown", "sig_frost_glacier", "sig_volt_storm"',
        '"victory", "defeat"',
    ]:
        if required not in audio:
            errors.append(f"AudioManager overlap guard missing: {required}")

    for stale in [
        'AudioManager.play_sfx("defeat", 1.0, 0.0)',
        'AudioManager.play_sfx("victory" if victory else "defeat", 1.0, 0.0)',
    ]:
        if stale in battle:
            errors.append(f"battle finish must not pre-play result stingers: {stale}")

    if result.count('AudioManager.play_bgm("victory" if victory else "defeat")') != 1:
        errors.append("result scene must own exactly one victory/defeat BGM switch")
    if result.count('AudioManager.play_sfx("victory" if victory else "defeat")') != 1:
        errors.append("result scene must own exactly one victory/defeat stinger")

    for scene_name, scene_source in [("loadout", loadout), ("collection", collection)]:
        if 'AudioManager.play_bgm("map")' not in scene_source:
            errors.append(f"{scene_name} must restore map/meta BGM on entry")

    for path in ROOT.rglob("*"):
        if path.parts[-1].startswith("."):
            continue
        rel = path.relative_to(ROOT)
        if rel.parts and rel.parts[0] in {".git", ".godot", "assets", "tmp"}:
            continue
        if path.suffix not in {".gd", ".tscn"}:
            continue
        text = path.read_text(errors="ignore")
        if "AudioStreamPlayer.new()" in text and rel.as_posix() != "core/audio/audio_manager.gd":
            errors.append(f"AudioStreamPlayer.new outside AudioManager: {rel}")
        if "[node" in text and "AudioStreamPlayer" in text:
            errors.append(f"scene-local AudioStreamPlayer node found: {rel}")

    if errors:
        for error in errors:
            print(f"audio overlap check failed: {error}", file=sys.stderr)
        return 1

    print("Audio overlap OK: BGM is singleton, long stingers are mutexed, result cue is single-owned")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
