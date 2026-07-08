#!/usr/bin/env python3
from __future__ import annotations

import math
import sys
import wave
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
SFX_DIR = ROOT / "assets/production/audio/sfx"

SHOT_FILES = {
	"sfx_shot_autocannon.wav",
	"sfx_shot_scattergun.wav",
	"sfx_shot_railgun.wav",
	"sfx_shot_plasmacannon.wav",
	"sfx_shot_flamethrower.wav",
	"sfx_shot_cryocannon.wav",
	"sfx_shot_teslacoil.wav",
	"sfx_shot_venomlauncher.wav",
}

MUZZLE_FILES = {
	"sfx_muzzle_fire.wav",
	"sfx_muzzle_ice.wav",
	"sfx_muzzle_lightning.wav",
	"sfx_muzzle_poison.wav",
}


def wav_data(path: Path) -> tuple[np.ndarray, int, int]:
	with wave.open(str(path), "rb") as wf:
		channels = wf.getnchannels()
		sr = wf.getframerate()
		frames = wf.getnframes()
		raw = wf.readframes(frames)
	arr = np.frombuffer(raw, dtype="<i2").astype(np.float64) / 32768.0
	return arr, sr, channels


def band_ratios(arr: np.ndarray, sr: int) -> tuple[float, float, float]:
	if arr.size < 2:
		return 0.0, 0.0, 0.0
	spec = np.abs(np.fft.rfft(arr * np.hanning(arr.size))) ** 2
	freqs = np.fft.rfftfreq(arr.size, 1.0 / sr)
	def band(low: float, high: float) -> float:
		mask = (freqs >= low) & (freqs < high)
		return float(spec[mask].sum())
	low = band(60.0, 350.0)
	mid = band(350.0, 2500.0)
	high = band(2500.0, 12000.0)
	total = low + mid + high + 1e-12
	return low / total, mid / total, high / total


def metrics(path: Path) -> dict[str, float]:
	arr, sr, channels = wav_data(path)
	peak = float(np.max(np.abs(arr))) if arr.size else 0.0
	rms = float(np.sqrt(np.mean(arr * arr))) if arr.size else 0.0
	zcr = float(np.mean(np.abs(np.diff(np.signbit(arr))))) if arr.size > 1 else 0.0
	low, mid, high = band_ratios(arr, sr)
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
	}


def main() -> int:
	errors: list[str] = []
	for name in sorted(SHOT_FILES | MUZZLE_FILES):
		path = SFX_DIR / name
		if not path.exists():
			errors.append(f"missing weapon sfx: {path.relative_to(ROOT)}")
			continue
		m = metrics(path)
		if int(m["sample_rate"]) != 44100:
			errors.append(f"{name} sample rate must be 44100 Hz")
		if int(m["channels"]) != 1:
			errors.append(f"{name} must be mono for predictable mobile mix")
		if not (0.09 <= m["duration"] <= 0.28):
			errors.append(f"{name} duration {m['duration']:.3f}s outside 0.09-0.28s")
		if not (-5.5 <= m["peak_db"] <= -3.0):
			errors.append(f"{name} peak {m['peak_db']:.2f} dBFS outside -5.5 to -3.0")
		if not (-18.5 <= m["rms_db"] <= -10.0):
			errors.append(f"{name} rms {m['rms_db']:.2f} dBFS outside -18.5 to -10.0")
		if m["zero_cross_rate"] < 0.060:
			errors.append(f"{name} zero-crossing too low ({m['zero_cross_rate']:.3f}); may sound tonal/croaky")
		if m["low_ratio"] > 0.42:
			errors.append(f"{name} low-frequency dominance too high ({m['low_ratio']:.2f}); may sound like a croak")
		if name in MUZZLE_FILES and m["high_ratio"] < 0.30:
			errors.append(f"{name} muzzle lacks broadband crack/hiss ({m['high_ratio']:.2f})")
		if name in SHOT_FILES and m["high_ratio"] < 0.10:
			errors.append(f"{name} shot lacks firearm transient brightness ({m['high_ratio']:.2f})")

	if errors:
		for error in errors:
			print(f"weapon sfx quality check failed: {error}", file=sys.stderr)
		return 1
	print("Weapon SFX quality OK: shot/muzzle files are short, broadband, and not low-frequency croak dominated")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
