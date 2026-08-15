#!/usr/bin/env python3
from __future__ import annotations

import math
import sys
import wave
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
SFX_DIR = ROOT / "assets/production/audio/sfx"
FILES = {
    "base": "sfx_enemy_breach.wav",
    "blink": "sfx_zombie_phantom.wav",
    "claw": "sfx_enemy_attack_claw.wav",
    "fast_claw": "sfx_enemy_attack_fast_claw.wav",
    "bite": "sfx_enemy_attack_bite.wav",
    "heavy_slam": "sfx_enemy_attack_heavy_slam.wav",
    "blast": "sfx_enemy_attack_blast.wav",
    "corrosion": "sfx_enemy_attack_corrosion.wav",
    "support": "sfx_enemy_attack_support.wav",
}


def _read(path: Path) -> tuple[np.ndarray, int, int]:
    with wave.open(str(path), "rb") as wav_file:
        channels = wav_file.getnchannels()
        sample_rate = wav_file.getframerate()
        signal = np.frombuffer(wav_file.readframes(wav_file.getnframes()), dtype="<i2").astype(np.float64) / 32768.0
    return signal, sample_rate, channels


def _metrics(signal: np.ndarray, sample_rate: int) -> dict[str, float]:
    spectrum = np.abs(np.fft.rfft(signal * np.hanning(signal.size))) ** 2
    frequencies = np.fft.rfftfreq(signal.size, 1.0 / sample_rate)

    def energy(low: float, high: float) -> float:
        return float(spectrum[(frequencies >= low) & (frequencies < high)].sum())

    low = energy(40.0, 350.0)
    mid = energy(350.0, 2400.0)
    high = energy(2400.0, 12_000.0)
    air = energy(12_000.0, 19_000.0)
    total = low + mid + high + air + 1e-12
    centroid = float((frequencies * spectrum).sum() / max(float(spectrum.sum()), 1e-12))
    peak = float(np.max(np.abs(signal)))
    rms = float(np.sqrt(np.mean(signal * signal)))
    return {
        "duration": signal.size / sample_rate,
        "peak_db": 20.0 * math.log10(max(peak, 1e-12)),
        "rms_db": 20.0 * math.log10(max(rms, 1e-12)),
        "low": low / total,
        "mid": mid / total,
        "high": high / total,
        "air": air / total,
        "centroid": centroid,
        "zcr": float(np.mean(np.abs(np.diff(np.signbit(signal))))) if signal.size > 1 else 0.0,
    }


def _spectral_cosine(a: np.ndarray, b: np.ndarray) -> float:
    size = 8192
    a_spec = np.abs(np.fft.rfft(np.interp(np.linspace(0, a.size - 1, size), np.arange(a.size), a) * np.hanning(size)))
    b_spec = np.abs(np.fft.rfft(np.interp(np.linspace(0, b.size - 1, size), np.arange(b.size), b) * np.hanning(size)))
    return float(np.dot(a_spec, b_spec) / max(np.linalg.norm(a_spec) * np.linalg.norm(b_spec), 1e-12))


def main() -> int:
    errors: list[str] = []
    signals: dict[str, np.ndarray] = {}
    metrics: dict[str, dict[str, float]] = {}
    for identity, name in FILES.items():
        path = SFX_DIR / name
        if not path.exists():
            errors.append(f"missing combat foley SFX: {path.relative_to(ROOT)}")
            continue
        signal, sample_rate, channels = _read(path)
        signals[identity] = signal
        metrics[identity] = _metrics(signal, sample_rate)
        if sample_rate != 44_100:
            errors.append(f"{name} must be 44100 Hz")
        if channels != 1:
            errors.append(f"{name} must be mono")
        value = metrics[identity]
        if not (-6.2 <= value["peak_db"] <= -3.8):
            errors.append(f"{name} peak {value['peak_db']:.2f} dBFS outside -6.2..-3.8")
        if not (-26.0 <= value["rms_db"] <= -9.0):
            errors.append(f"{name} RMS {value['rms_db']:.2f} dBFS outside -26..-9")
    if "base" in metrics:
        value = metrics["base"]
        if not 0.40 <= value["duration"] <= 0.56:
            errors.append("base impact must retain a realistic 0.40..0.56s plate/grit decay")
        if value["low"] + value["mid"] < 0.62:
            errors.append("base impact lacks steel/body energy below 2.4 kHz")
        if value["high"] < 0.006:
            errors.append("base impact lacks bolt/grit detail")
    if "blink" in metrics:
        value = metrics["blink"]
        if not 0.34 <= value["duration"] <= 0.50:
            errors.append("phase blink must stay a short 0.34..0.50s wind cut")
        if value["low"] > 0.16:
            errors.append("phase blink has too much impact-like low end")
        if value["high"] + value["air"] < 0.34:
            errors.append("phase blink lacks broadband wind brightness")
        if value["centroid"] < 1800.0 or value["zcr"] < 0.09:
            errors.append("phase blink does not read as a noise-led air displacement")
    for identity in set(FILES) - {"base", "blink"}:
        if identity not in metrics:
            continue
        value = metrics[identity]
        if not 0.22 <= value["duration"] <= 0.48:
            errors.append(f"{identity} attack duration must stay in 0.22..0.48s")
    if "base" in signals and "blink" in signals:
        similarity = _spectral_cosine(signals["base"], signals["blink"])
        if similarity > 0.72:
            errors.append(f"base and blink spectra are still too similar ({similarity:.3f})")
    attack_centroids = [metrics[name]["centroid"] for name in set(FILES) - {"base", "blink"} if name in metrics]
    if attack_centroids and max(attack_centroids) - min(attack_centroids) < 900.0:
        errors.append("zombie attack families lack material/spectral range")

    audio_source = (ROOT / "core/audio/audio_manager.gd").read_text(encoding="utf-8")
    battle_source = (ROOT / "gameplay/battle/battle.gd").read_text(encoding="utf-8")
    for name in FILES.values():
        if name not in audio_source:
            errors.append(f"AudioManager does not register {name}")
    if "_play_zombie_base_attack_sfx(enemy)" not in battle_source:
        errors.append("ordinary zombie base attacks do not trigger their action-family SFX")
    if 'AudioManager.play_enemy_sfx("enemy_breach"' not in battle_source:
        errors.append("real base damage no longer triggers the dedicated barricade impact")
    runtime_contracts = {
        'func _enemy_advance_warning_sfx(_kind: String) -> String:':
            "advance movement still owns a second generic warning route",
        'return "" if kind == "phase" else "enemy_breach"':
            "phase slip damage still fakes a physical barricade impact",
        '"phase", "phase_shift", "charge":':
            "pangolin-like charger movement does not route to the clean wind-cut SFX",
        '_enemy_advance_reaches_base(old_y)':
            "advance movement does not guard base damage/contact by its starting distance",
        'return "zombie_phantom" if mode == "dash_combo" else ""':
            "Void Phantom dash motion does not route to the wind-cut SFX",
        '_enemy_skill_base_impact_sfx(kind)':
            "advance skills do not resolve their contact layer by movement kind",
        '_zombie_event_sfx(str(enemy.get("mechanic")) if is_instance_valid(enemy) else "", "death")':
            "zombie death still replays a mechanic/ability cue",
        'AudioManager.play_enemy_sfx(sfx_id, volume_db, pitch_variation)':
            "zombie actions bypass the exclusive enemy foley lane",
    }
    for source_fragment, error in runtime_contracts.items():
        if source_fragment not in battle_source:
            errors.append(error)

    if errors:
        for error in errors:
            print(f"combat foley SFX quality failed: {error}", file=sys.stderr)
        return 1
    print(
        "Combat foley SFX quality OK: one exclusive zombie lifecycle lane, realistic base impact, "
        "isolated phase/charger wind routing, and 7 distinct attack families"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
