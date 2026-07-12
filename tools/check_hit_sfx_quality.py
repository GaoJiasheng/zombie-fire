#!/usr/bin/env python3
from __future__ import annotations

import math
import sys
import wave
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
SFX_DIR = ROOT / "assets/production/audio/sfx"

HIT_FILES = {
	"physical": "sfx_hit_physical.wav",
	"fire": "sfx_hit_fire.wav",
	"ice": "sfx_hit_ice.wav",
	"lightning": "sfx_hit_lightning.wav",
	"poison": "sfx_hit_poison.wav",
	"immune": "sfx_hit_immune.wav",
}


def wav_data(path: Path) -> tuple[np.ndarray, int, int]:
	with wave.open(str(path), "rb") as wf:
		channels = wf.getnchannels()
		sr = wf.getframerate()
		frames = wf.getnframes()
		raw = wf.readframes(frames)
	arr = np.frombuffer(raw, dtype="<i2").astype(np.float64) / 32768.0
	return arr, sr, channels


def band_ratios(arr: np.ndarray, sr: int) -> tuple[float, float, float, float]:
	if arr.size < 2:
		return 0.0, 0.0, 0.0, 0.0
	spec = np.abs(np.fft.rfft(arr * np.hanning(arr.size))) ** 2
	freqs = np.fft.rfftfreq(arr.size, 1.0 / sr)

	def band(low: float, high: float) -> float:
		mask = (freqs >= low) & (freqs < high)
		return float(spec[mask].sum())

	low = band(60.0, 350.0)
	mid = band(350.0, 2500.0)
	high = band(2500.0, 12000.0)
	air = band(12000.0, 18000.0)
	total = low + mid + high + air + 1e-12
	return low / total, mid / total, high / total, air / total


def metrics(path: Path) -> dict[str, float]:
	arr, sr, channels = wav_data(path)
	peak = float(np.max(np.abs(arr))) if arr.size else 0.0
	rms = float(np.sqrt(np.mean(arr * arr))) if arr.size else 0.0
	zcr = float(np.mean(np.abs(np.diff(np.signbit(arr))))) if arr.size > 1 else 0.0
	low, mid, high, air = band_ratios(arr, sr)
	return {
		"sample_rate": float(sr),
		"channels": float(channels),
		"duration": arr.size / max(sr, 1),
		"peak_db": 20.0 * math.log10(max(peak, 1e-9)),
		"rms_db": 20.0 * math.log10(max(rms, 1e-9)),
		"zero_cross_rate": zcr,
		"low_ratio": low,
		"mid_ratio": mid,
		"high_ratio": high,
		"air_ratio": air,
	}


def main() -> int:
	errors: list[str] = []
	collected: dict[str, dict[str, float]] = {}
	for element, name in HIT_FILES.items():
		path = SFX_DIR / name
		if not path.exists():
			errors.append(f"missing hit sfx: {path.relative_to(ROOT)}")
			continue
		m = metrics(path)
		collected[element] = m
		if int(m["sample_rate"]) != 44100:
			errors.append(f"{name} sample rate must be 44100 Hz")
		if int(m["channels"]) != 1:
			errors.append(f"{name} must be mono for predictable mobile mix")
		if not (0.095 <= m["duration"] <= 0.245):
			errors.append(f"{name} duration {m['duration']:.3f}s outside 0.095-0.245s")
		if not (-6.2 <= m["peak_db"] <= -3.2):
			errors.append(f"{name} peak {m['peak_db']:.2f} dBFS outside -6.2 to -3.2")
		if not (-25.5 <= m["rms_db"] <= -10.0):
			errors.append(f"{name} rms {m['rms_db']:.2f} dBFS outside -25.5 to -10.0")
		if m["low_ratio"] > 0.38:
			errors.append(f"{name} low-frequency dominance too high ({m['low_ratio']:.2f}); hit may read croaky/muddy")
		if m["zero_cross_rate"] < 0.045:
			errors.append(f"{name} zero-crossing too low ({m['zero_cross_rate']:.3f}); hit may be too tonal")

	if collected:
		physical = collected.get("physical", {})
		fire = collected.get("fire", {})
		ice = collected.get("ice", {})
		lightning = collected.get("lightning", {})
		poison = collected.get("poison", {})
		immune = collected.get("immune", {})
		if physical and physical["mid_ratio"] < 0.30:
			errors.append("physical hit must keep a mid-band collision body")
		if fire and fire["duration"] < 0.17:
			errors.append("fire hit must include a short sizzle tail")
		if fire and fire["high_ratio"] < 0.20:
			errors.append("fire hit must have enough crackle/hiss brightness")
		if ice and ice["high_ratio"] + ice["air_ratio"] < 0.42:
			errors.append("ice hit must read as brittle crystal shatter")
		if lightning and lightning["high_ratio"] + lightning["air_ratio"] < 0.52:
			errors.append("lightning hit must read as bright electric crack")
		if poison and poison["duration"] < 0.19:
			errors.append("poison hit must include corrosive splash tail")
		if immune and immune["mid_ratio"] < 0.22:
			errors.append("immune hit must keep a shield/metal ping body")
		if physical and lightning and lightning["high_ratio"] <= physical["high_ratio"] + 0.10:
			errors.append("lightning hit should be clearly brighter than physical hit")
		if ice and fire and abs((ice["high_ratio"] + ice["air_ratio"]) - (fire["high_ratio"] + fire["air_ratio"])) < 0.10:
			errors.append("ice and fire hit spectra are too similar")

	if errors:
		for error in errors:
			print(f"hit sfx quality check failed: {error}", file=sys.stderr)
		return 1
	print("Hit SFX quality OK: projectile impacts are short, mono, and element-distinct")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
