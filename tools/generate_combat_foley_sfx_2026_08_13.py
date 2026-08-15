#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import math
import shutil
import wave
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


SR = 44_100
ROOT = Path(__file__).resolve().parents[1]
SFX_DIR = ROOT / "assets/production/audio/sfx"
REF_DIR = ROOT / "assets/production/source_refs/generated/combat_foley_sfx_2026_08_13"
ORIGINAL_DIR = REF_DIR / "original_sfx"
RNG = np.random.default_rng(20260813)


def _empty(duration: float) -> np.ndarray:
    return np.zeros(max(1, int(round(duration * SR))), dtype=np.float64)


def _time(duration: float) -> np.ndarray:
    return np.arange(max(1, int(round(duration * SR))), dtype=np.float64) / SR


def _norm(signal: np.ndarray, peak: float = 1.0) -> np.ndarray:
    current = float(np.max(np.abs(signal))) if signal.size else 0.0
    return signal if current < 1e-12 else signal / current * peak


def _band_noise(duration: float, low: float, high: float) -> np.ndarray:
    count = max(2, int(round(duration * SR)))
    spectrum = np.fft.rfft(RNG.normal(0.0, 1.0, count))
    frequencies = np.fft.rfftfreq(count, 1.0 / SR)
    edge = max(40.0, min(360.0, (high - low) * 0.08))
    response = np.zeros_like(frequencies)
    inner = (frequencies >= low + edge) & (frequencies <= high - edge)
    response[inner] = 1.0
    lower = (frequencies >= low) & (frequencies < low + edge)
    upper = (frequencies > high - edge) & (frequencies <= high)
    response[lower] = np.sin((frequencies[lower] - low) / edge * math.pi * 0.5) ** 2
    response[upper] = np.sin((high - frequencies[upper]) / edge * math.pi * 0.5) ** 2
    return _norm(np.fft.irfft(spectrum * response, count))


def _envelope(duration: float, points: list[tuple[float, float]]) -> np.ndarray:
    count = max(1, int(round(duration * SR)))
    x = np.arange(count, dtype=np.float64) / SR
    times = np.array([point[0] for point in points], dtype=np.float64)
    values = np.array([point[1] for point in points], dtype=np.float64)
    return np.interp(x, times, values, left=values[0], right=values[-1])


def _decay(duration: float, start: float, tau: float, attack: float = 0.002) -> np.ndarray:
    t = _time(duration)
    result = np.zeros_like(t)
    active = t >= start
    result[active] = np.exp(-(t[active] - start) / max(tau, 0.001))
    attack_count = min(result.size, max(1, int(round((start + attack) * SR))))
    start_count = min(result.size, max(0, int(round(start * SR))))
    if attack_count > start_count:
        result[start_count:attack_count] *= np.linspace(0.0, 1.0, attack_count - start_count)
    return result


def _tone(freq: float, duration: float, phase: float = 0.0) -> np.ndarray:
    t = _time(duration)
    return np.sin(math.tau * freq * t + phase)


def _chirp(start: float, end: float, duration: float, phase: float = 0.0) -> np.ndarray:
    t = _time(duration)
    slope = (end - start) / max(duration, 0.001)
    return np.sin(math.tau * (start * t + 0.5 * slope * t * t) + phase)


def _add(destination: np.ndarray, source: np.ndarray, at: float, gain: float = 1.0) -> None:
    start = int(round(at * SR))
    if start >= destination.size:
        return
    end = min(destination.size, start + source.size)
    destination[start:end] += source[: end - start] * gain


def _impact(duration: float, low: float, high: float, body: float = 0.72) -> np.ndarray:
    signal = _band_noise(duration, low, high) * _decay(duration, 0.0, duration * 0.22, 0.0015)
    signal += _band_noise(duration, 900.0, 7500.0) * _decay(duration, 0.0, duration * 0.08, 0.0007) * 0.28
    signal += _tone(max(52.0, low * 1.18), duration, RNG.uniform(0.0, math.tau)) * _decay(duration, 0.0, duration * 0.24) * body
    return signal


def _wet(duration: float) -> np.ndarray:
    signal = _band_noise(duration, 90.0, 1700.0) * _envelope(
        duration,
        [(0.0, 0.0), (0.012, 1.0), (duration * 0.28, 0.62), (duration, 0.0)],
    )
    signal += _chirp(380.0, 96.0, duration) * _decay(duration, 0.0, duration * 0.30) * 0.32
    return signal


def _whoosh(duration: float, bright: bool = True) -> np.ndarray:
    low, high = (720.0, 12_500.0) if bright else (280.0, 6_800.0)
    signal = _band_noise(duration, low, high)
    signal *= _envelope(
        duration,
        [(0.0, 0.0), (duration * 0.12, 0.42), (duration * 0.30, 1.0), (duration * 0.62, 0.38), (duration, 0.0)],
    )
    return signal


def base_breach() -> np.ndarray:
    """Steel barricade flex, sandbag thump and loose fastener rattle."""
    duration = 0.48
    signal = _empty(duration)
    _add(signal, _impact(0.32, 55.0, 520.0, 0.80), 0.006, 0.82)
    for frequency, gain, tau in ((238.0, 0.30, 0.17), (411.0, 0.24, 0.14), (733.0, 0.16, 0.11), (1280.0, 0.10, 0.075)):
        signal += _tone(frequency, duration, RNG.uniform(0.0, math.tau)) * _decay(duration, 0.010, tau) * gain
    signal += _band_noise(duration, 1200.0, 8600.0) * _decay(duration, 0.010, 0.045, 0.0008) * 0.30
    # Loose bolts and masonry grit settle after the main plate flex.
    for at, frequency, gain in ((0.082, 1780.0, 0.15), (0.126, 2460.0, 0.11), (0.194, 1320.0, 0.09), (0.258, 2050.0, 0.06)):
        tick = _tone(frequency, 0.052, RNG.uniform(0.0, math.tau)) * _decay(0.052, 0.0, 0.013)
        tick += _band_noise(0.052, 1800.0, 9200.0) * _decay(0.052, 0.0, 0.010) * 0.5
        _add(signal, tick, at, gain)
    return signal


def phantom_whoosh() -> np.ndarray:
    """A clean air displacement: no electric zap and no impact transient."""
    duration = 0.44
    signal = _whoosh(duration, True) * 0.88
    signal += _band_noise(duration, 340.0, 2600.0) * _envelope(
        duration,
        [(0.0, 0.0), (0.055, 0.18), (0.13, 0.62), (0.25, 0.22), (duration, 0.0)],
    ) * 0.40
    # A second, thinner wake gives the requested quick “shua” tail.
    wake = _band_noise(0.24, 1800.0, 13_500.0) * _envelope(
        0.24,
        [(0.0, 0.0), (0.025, 0.68), (0.075, 1.0), (0.24, 0.0)],
    )
    _add(signal, wake, 0.105, 0.36)
    return signal


def attack_claw() -> np.ndarray:
    duration = 0.31
    signal = _whoosh(duration, True) * 0.58
    for at in (0.105, 0.132, 0.160):
        scrape = _band_noise(0.105, 780.0, 7200.0) * _decay(0.105, 0.0, 0.028, 0.001)
        _add(signal, scrape, at, 0.34)
    _add(signal, _wet(0.14), 0.145, 0.28)
    return signal


def attack_fast_claw() -> np.ndarray:
    duration = 0.27
    signal = _empty(duration)
    _add(signal, _whoosh(0.16, True), 0.0, 0.48)
    _add(signal, _whoosh(0.14, True), 0.072, 0.58)
    _add(signal, _band_noise(0.085, 1000.0, 9000.0) * _decay(0.085, 0.0, 0.020), 0.125, 0.36)
    return signal


def attack_bite() -> np.ndarray:
    duration = 0.28
    signal = _empty(duration)
    _add(signal, _whoosh(0.14, False), 0.0, 0.30)
    snap = _impact(0.15, 130.0, 2100.0, 0.32)
    _add(signal, snap, 0.082, 0.74)
    _add(signal, _wet(0.15), 0.105, 0.48)
    return signal


def attack_heavy_slam() -> np.ndarray:
    duration = 0.42
    signal = _empty(duration)
    _add(signal, _whoosh(0.27, False), 0.0, 0.30)
    _add(signal, _impact(0.30, 42.0, 410.0, 0.95), 0.115, 0.88)
    _add(signal, _band_noise(0.17, 450.0, 3400.0) * _decay(0.17, 0.0, 0.048), 0.135, 0.22)
    return signal


def attack_blast() -> np.ndarray:
    duration = 0.44
    signal = _empty(duration)
    signal += _band_noise(duration, 900.0, 10_000.0) * _envelope(
        duration,
        [(0.0, 0.0), (0.055, 0.20), (0.14, 0.72), (0.19, 1.0), (duration, 0.0)],
    ) * 0.48
    _add(signal, _impact(0.27, 48.0, 620.0, 0.80), 0.145, 0.72)
    for at in (0.205, 0.249, 0.301):
        _add(signal, _band_noise(0.06, 1300.0, 7800.0) * _decay(0.06, 0.0, 0.014), at, 0.12)
    return signal


def attack_corrosion() -> np.ndarray:
    duration = 0.39
    signal = _empty(duration)
    _add(signal, _wet(0.24), 0.035, 0.62)
    signal += _band_noise(duration, 2600.0, 13_000.0) * _envelope(
        duration,
        [(0.0, 0.0), (0.08, 0.18), (0.14, 0.72), (0.24, 0.48), (duration, 0.0)],
    ) * 0.45
    for at in (0.13, 0.185, 0.24):
        bubble = _chirp(510.0, 170.0, 0.07) * _decay(0.07, 0.0, 0.022)
        _add(signal, bubble, at, 0.20)
    return signal


def attack_support() -> np.ndarray:
    duration = 0.41
    signal = _band_noise(duration, 170.0, 1700.0) * _envelope(
        duration,
        [(0.0, 0.0), (0.055, 0.30), (0.13, 0.86), (0.23, 0.48), (duration, 0.0)],
    ) * 0.58
    signal += _chirp(310.0, 760.0, duration) * _envelope(
        duration,
        [(0.0, 0.0), (0.08, 0.16), (0.17, 0.46), (0.31, 0.12), (duration, 0.0)],
    ) * 0.28
    _add(signal, _whoosh(0.21, True), 0.12, 0.26)
    return signal


ASSETS = {
    "sfx_enemy_breach.wav": (base_breach, "realistic steel barricade and sandbag impact"),
    "sfx_zombie_phantom.wav": (phantom_whoosh, "phase blink air-cut whoosh without zap or impact"),
    "sfx_enemy_attack_claw.wav": (attack_claw, "ordinary claw swipe with flesh scrape"),
    "sfx_enemy_attack_fast_claw.wav": (attack_fast_claw, "two quick light claw swipes"),
    "sfx_enemy_attack_bite.wav": (attack_bite, "jaw snap and wet bite"),
    "sfx_enemy_attack_heavy_slam.wav": (attack_heavy_slam, "heavy body/limb slam"),
    "sfx_enemy_attack_blast.wav": (attack_blast, "organic explosive attack release"),
    "sfx_enemy_attack_corrosion.wav": (attack_corrosion, "wet acid contact and corrosive sizzle"),
    "sfx_enemy_attack_support.wav": (attack_support, "support caster vocal swipe"),
}


def _master(signal: np.ndarray, peak_db: float = -4.8) -> np.ndarray:
    signal = np.nan_to_num(signal)
    signal = np.tanh(signal * 1.12) / math.tanh(1.12)
    signal = _norm(signal, 10.0 ** (peak_db / 20.0))
    fade = min(signal.size, int(round(0.012 * SR)))
    if fade > 1:
        signal[-fade:] *= np.linspace(1.0, 0.0, fade)
    return np.clip(signal, -0.98, 0.98)


def _write_wav(path: Path, signal: np.ndarray) -> dict:
    path.parent.mkdir(parents=True, exist_ok=True)
    output = _master(signal)
    with wave.open(str(path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SR)
        wav_file.writeframes((output * 32767.0).astype("<i2").tobytes())
    peak = float(np.max(np.abs(output)))
    rms = float(np.sqrt(np.mean(output * output)))
    return {
        "path": str(path.relative_to(ROOT)),
        "duration_sec": round(output.size / SR, 3),
        "sample_rate": SR,
        "channels": 1,
        "peak_dbfs": round(20.0 * math.log10(max(peak, 1e-12)), 2),
        "rms_dbfs": round(20.0 * math.log10(max(rms, 1e-12)), 2),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def _waveform_sheet(records: list[dict]) -> Path:
    width, cell_height = 1120, 118
    image = Image.new("RGB", (width, cell_height * len(records)), (10, 14, 18))
    draw = ImageDraw.Draw(image)
    try:
        font = ImageFont.truetype("Arial.ttf", 15)
    except OSError:
        font = ImageFont.load_default()
    for row, record in enumerate(records):
        y0 = row * cell_height
        draw.rectangle((8, y0 + 8, width - 8, y0 + cell_height - 8), outline=(62, 86, 102), width=1)
        draw.text((18, y0 + 14), Path(record["path"]).name, fill=(232, 238, 242), font=font)
        draw.text(
            (18, y0 + 36),
            f'{record["duration_sec"]:.3f}s  peak {record["peak_dbfs"]:.2f} dBFS  rms {record["rms_dbfs"]:.2f} dBFS',
            fill=(146, 178, 194),
            font=font,
        )
        with wave.open(str(ROOT / record["path"]), "rb") as wav_file:
            signal = np.frombuffer(wav_file.readframes(wav_file.getnframes()), dtype="<i2").astype(np.float64) / 32768.0
        waveform_width = width - 40
        samples = np.interp(np.linspace(0, signal.size - 1, waveform_width), np.arange(signal.size), signal)
        center = y0 + 84
        color = (244, 174, 76) if "breach" in record["path"] else (106, 218, 238) if "phantom" in record["path"] else (196, 112, 88)
        for x, value in enumerate(samples):
            height = int(abs(value) * 28)
            draw.line((20 + x, center - height, 20 + x, center + height), fill=color)
    path = REF_DIR / "combat_foley_sfx_waveform_sheet_2026_08_13.png"
    image.save(path)
    return path


def main() -> int:
    REF_DIR.mkdir(parents=True, exist_ok=True)
    ORIGINAL_DIR.mkdir(parents=True, exist_ok=True)
    for name in ("sfx_enemy_breach.wav", "sfx_zombie_phantom.wav"):
        source = SFX_DIR / name
        backup = ORIGINAL_DIR / name
        if source.exists() and not backup.exists():
            shutil.copy2(source, backup)
    records = []
    for name, (builder, description) in ASSETS.items():
        record = _write_wav(SFX_DIR / name, builder())
        record["description"] = description
        records.append(record)
    sheet = _waveform_sheet(records)
    manifest = {
        "version": 1,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "task": "base impact realism, phase-blink wind cut, and zombie attack-family separation",
        "technical_contract": {
            "format": "PCM WAV",
            "sample_rate": SR,
            "channels": 1,
            "target_peak_dbfs": -4.8,
        },
        "semantic_contract": {
            "enemy_breach": "physical barricade contact only; never used as a zombie action cue",
            "zombie_phantom": "air displacement only; no electric arc, explosion, or metal hit",
            "enemy_attack_family": "zombie action/material layer; base contact is a separate concurrent layer",
        },
        "assets": records,
        "waveform_sheet": str(sheet.relative_to(ROOT)),
    }
    manifest_path = REF_DIR / "combat_foley_sfx_manifest_2026_08_13.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Generated {len(records)} combat foley SFX")
    print(manifest_path.relative_to(ROOT))
    print(sheet.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
