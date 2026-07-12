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


ROOT = Path(__file__).resolve().parents[1]
SFX_DIR = ROOT / "assets/production/audio/sfx"
REF_DIR = ROOT / "assets/production/source_refs/generated/hit_sfx_impact_2026_07_08"
INDEX_PATH = ROOT / "assets/production/OUTSOURCER_ASSET_INDEX.json"
SR = 44100
TAU = math.tau
TARGET_PEAK = 10 ** (-4.8 / 20.0)
RNG = np.random.default_rng(20260708)

FILES = {
	"physical": "sfx_hit_physical.wav",
	"fire": "sfx_hit_fire.wav",
	"ice": "sfx_hit_ice.wav",
	"lightning": "sfx_hit_lightning.wav",
	"poison": "sfx_hit_poison.wav",
	"immune": "sfx_hit_immune.wav",
}


def rel(path: Path) -> str:
	return path.relative_to(ROOT).as_posix()


def t(duration: float) -> np.ndarray:
	return np.arange(max(1, int(round(duration * SR))), dtype=np.float64) / SR


def empty(duration: float) -> np.ndarray:
	return np.zeros(max(1, int(round(duration * SR))), dtype=np.float64)


def env_decay(duration: float, tau: float, attack: float = 0.0005) -> np.ndarray:
	x = t(duration)
	out = np.exp(-x / max(tau, 0.001))
	a = min(len(out), max(1, int(round(attack * SR))))
	out[:a] *= np.linspace(0.0, 1.0, a) ** 0.7
	return out


def fade_tail(x: np.ndarray, seconds: float) -> np.ndarray:
	n = min(len(x), max(1, int(round(seconds * SR))))
	y = x.copy()
	y[-n:] *= np.linspace(1.0, 0.0, n) ** 1.35
	return y


def norm(x: np.ndarray, peak: float = 1.0) -> np.ndarray:
	m = float(np.max(np.abs(x))) if x.size else 0.0
	if m < 1e-9:
		return x
	return x / m * peak


def soft_clip(x: np.ndarray, drive: float = 1.2) -> np.ndarray:
	return np.tanh(x * drive) / math.tanh(drive)


def band_noise(duration: float, low: float, high: float) -> np.ndarray:
	n = max(2, int(round(duration * SR)))
	noise = RNG.normal(0.0, 1.0, n)
	spec = np.fft.rfft(noise)
	freqs = np.fft.rfftfreq(n, 1.0 / SR)
	spec *= (freqs >= low) & (freqs <= high)
	return norm(np.fft.irfft(spec, n))


def tone(freq: float, duration: float, phase: float = 0.0) -> np.ndarray:
	return np.sin(TAU * freq * t(duration) + phase)


def chirp(start: float, end: float, duration: float, phase: float = 0.0) -> np.ndarray:
	x = t(duration)
	k = (end - start) / max(duration, 0.001)
	return np.sin(TAU * (start * x + 0.5 * k * x * x) + phase)


def add(dst: np.ndarray, src: np.ndarray, at: float, gain: float = 1.0) -> None:
	start = max(0, int(round(at * SR)))
	end = min(len(dst), start + len(src))
	if end > start:
		dst[start:end] += src[: end - start] * gain


def click(duration: float, low: float, high: float, tau: float, gain: float = 1.0) -> np.ndarray:
	return band_noise(duration, low, high) * env_decay(duration, tau, 0.00018) * gain


def physical_hit() -> np.ndarray:
	d = 0.125
	x = empty(d)
	add(x, click(0.040, 240.0, 4800.0, 0.014, 0.80), 0.000)
	add(x, click(0.032, 2600.0, 11800.0, 0.007, 0.46), 0.002)
	add(x, band_noise(0.075, 90.0, 620.0) * env_decay(0.075, 0.030, 0.001), 0.004, 0.22)
	for at, freq, gain in [(0.008, 820.0, 0.10), (0.019, 1470.0, 0.08), (0.036, 2430.0, 0.06)]:
		add(x, tone(freq, 0.055, RNG.random() * TAU) * env_decay(0.055, 0.021, 0.0004), at, gain)
	return fade_tail(x, 0.032)


def fire_hit() -> np.ndarray:
	d = 0.205
	x = empty(d)
	add(x, click(0.052, 800.0, 12500.0, 0.011, 0.52), 0.000)
	add(x, band_noise(0.155, 220.0, 5800.0) * env_decay(0.155, 0.070, 0.002), 0.010, 0.66)
	add(x, band_noise(0.105, 2800.0, 14800.0) * env_decay(0.105, 0.033, 0.0004), 0.018, 0.44)
	add(x, band_noise(0.050, 95.0, 310.0) * env_decay(0.050, 0.032, 0.001), 0.012, 0.07)
	for at in [0.030, 0.062, 0.096, 0.136]:
		add(x, click(0.020, 4200.0, 15000.0, 0.004, 0.13), at)
	return fade_tail(x, 0.060)


def ice_hit() -> np.ndarray:
	d = 0.185
	x = empty(d)
	add(x, click(0.036, 1900.0, 16000.0, 0.008, 0.72), 0.000)
	add(x, click(0.026, 5200.0, 18000.0, 0.004, 0.48), 0.018)
	add(x, click(0.030, 3300.0, 15000.0, 0.005, 0.36), 0.045)
	for at, freq, gain in [(0.006, 2850.0, 0.25), (0.027, 4120.0, 0.20), (0.061, 5250.0, 0.16), (0.095, 2360.0, 0.11)]:
		add(x, tone(freq, 0.075, RNG.random() * TAU) * env_decay(0.075, 0.030, 0.0004), at, gain)
	add(x, band_noise(0.120, 900.0, 7000.0) * env_decay(0.120, 0.046, 0.001), 0.012, 0.20)
	return fade_tail(x, 0.045)


def lightning_hit() -> np.ndarray:
	d = 0.165
	x = empty(d)
	for at, gain in [(0.000, 0.72), (0.027, 0.56), (0.058, 0.46), (0.092, 0.30)]:
		add(x, click(0.044, 2600.0, 18500.0, 0.009, gain), at)
		add(x, chirp(7800.0, 1350.0, 0.045, RNG.random() * TAU) * env_decay(0.045, 0.014, 0.0002), at, gain * 0.23)
	add(x, band_noise(0.095, 180.0, 900.0) * env_decay(0.095, 0.038, 0.001), 0.010, 0.08)
	return fade_tail(x, 0.032)


def poison_hit() -> np.ndarray:
	d = 0.220
	x = empty(d)
	add(x, click(0.040, 550.0, 6900.0, 0.013, 0.48), 0.000)
	add(x, band_noise(0.178, 380.0, 5200.0) * env_decay(0.178, 0.090, 0.003), 0.014, 0.58)
	add(x, band_noise(0.100, 2200.0, 12500.0) * env_decay(0.100, 0.042, 0.0006), 0.020, 0.30)
	for at in [0.030, 0.071, 0.119, 0.166]:
		add(x, chirp(520.0, 1120.0, 0.035, RNG.random() * TAU) * env_decay(0.035, 0.025, 0.001), at, 0.10)
	return fade_tail(x, 0.070)


def immune_hit() -> np.ndarray:
	d = 0.165
	x = empty(d)
	add(x, click(0.030, 900.0, 12000.0, 0.007, 0.54), 0.000)
	add(x, tone(1180.0, 0.120, RNG.random() * TAU) * env_decay(0.120, 0.052, 0.0005), 0.003, 0.25)
	add(x, tone(2360.0, 0.095, RNG.random() * TAU) * env_decay(0.095, 0.038, 0.0004), 0.010, 0.18)
	add(x, chirp(3900.0, 1850.0, 0.100, RNG.random() * TAU) * env_decay(0.100, 0.040, 0.0004), 0.014, 0.16)
	add(x, band_noise(0.085, 2500.0, 14000.0) * env_decay(0.085, 0.022, 0.0003), 0.018, 0.18)
	return fade_tail(x, 0.045)


GENERATORS = {
	"physical": physical_hit,
	"fire": fire_hit,
	"ice": ice_hit,
	"lightning": lightning_hit,
	"poison": poison_hit,
	"immune": immune_hit,
}


def master(x: np.ndarray) -> np.ndarray:
	x = np.nan_to_num(x, copy=False)
	x -= float(np.mean(x)) if x.size else 0.0
	x = 0.78 * x + 0.22 * soft_clip(x * 2.3, 1.7)
	x = soft_clip(x, 1.95)
	x = norm(x, TARGET_PEAK)
	return np.clip(x, -0.985, 0.985)


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


def metrics(arr: np.ndarray, sr: int, channels: int, path: str, sha: str) -> dict:
	peak = float(np.max(np.abs(arr))) if arr.size else 0.0
	rms = float(np.sqrt(np.mean(arr * arr))) if arr.size else 0.0
	zcr = float(np.mean(np.abs(np.diff(np.signbit(arr))))) if arr.size > 1 else 0.0
	low, mid, high, air = band_ratios(arr, sr)
	return {
		"path": path,
		"duration_sec": round(arr.size / max(sr, 1), 3),
		"sample_rate": sr,
		"channels": channels,
		"peak_dbfs": round(20.0 * math.log10(max(peak, 1e-9)), 2),
		"rms_dbfs": round(20.0 * math.log10(max(rms, 1e-9)), 2),
		"zero_cross_rate": round(zcr, 4),
		"low_ratio_60_350": round(low, 4),
		"mid_ratio_350_2500": round(mid, 4),
		"high_ratio_2500_12000": round(high, 4),
		"air_ratio_12000_18000": round(air, 4),
		"sha256": sha,
	}


def read_wav_metrics(path: Path) -> dict:
	with wave.open(str(path), "rb") as wf:
		sr = wf.getframerate()
		channels = wf.getnchannels()
		frames = wf.getnframes()
		raw = wf.readframes(frames)
	arr = np.frombuffer(raw, dtype="<i2").astype(np.float64) / 32768.0
	return metrics(arr, sr, channels, rel(path), hashlib.sha256(path.read_bytes()).hexdigest())


def write_wav(path: Path, x: np.ndarray) -> dict:
	y = master(x)
	pcm = (y * 32767.0).astype("<i2")
	with wave.open(str(path), "wb") as wf:
		wf.setnchannels(1)
		wf.setsampwidth(2)
		wf.setframerate(SR)
		wf.writeframes(pcm.tobytes())
	return metrics(y, SR, 1, rel(path), hashlib.sha256(path.read_bytes()).hexdigest())


def waveform_sheet(entries: list[dict], out_path: Path) -> None:
	width = 1400
	row_h = 140
	height = 78 + row_h * len(entries)
	img = Image.new("RGB", (width, height), (8, 12, 16))
	draw = ImageDraw.Draw(img)
	try:
		font_title = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 28)
		font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 17)
	except OSError:
		font_title = ImageFont.load_default()
		font = ImageFont.load_default()
	draw.text((28, 22), "Element Hit SFX Impact Pass - waveform / spectrum guard", fill=(235, 240, 244), font=font_title)
	for i, entry in enumerate(entries):
		y = 74 + i * row_h
		draw.rectangle((26, y, width - 26, y + row_h - 16), outline=(70, 95, 108), fill=(13, 21, 27))
		path = ROOT / entry["new"]["path"]
		with wave.open(str(path), "rb") as wf:
			arr = np.frombuffer(wf.readframes(wf.getnframes()), dtype="<i2").astype(np.float64) / 32768.0
		left = 310
		top = y + 24
		right = width - 40
		mid_y = y + 72
		color = {
			"physical": (200, 210, 220),
			"fire": (255, 126, 48),
			"ice": (112, 218, 255),
			"lightning": (255, 226, 72),
			"poison": (126, 232, 74),
			"immune": (190, 210, 232),
		}.get(entry["element"], (74, 214, 255))
		draw.text((42, y + 22), entry["element"], fill=(255, 213, 116), font=font)
		draw.text((42, y + 50), Path(entry["new"]["path"]).name, fill=(205, 224, 230), font=font)
		stats = entry["new"]
		draw.text((42, y + 78), f"{stats['duration_sec']:.3f}s peak {stats['peak_dbfs']:.1f} rms {stats['rms_dbfs']:.1f}", fill=(126, 156, 168), font=font)
		draw.text((42, y + 102), f"L/M/H/A {stats['low_ratio_60_350']:.2f}/{stats['mid_ratio_350_2500']:.2f}/{stats['high_ratio_2500_12000']:.2f}/{stats['air_ratio_12000_18000']:.2f}", fill=(126, 156, 168), font=font)
		if arr.size:
			step = max(1, int(math.ceil(arr.size / (right - left))))
			for x in range(left, right):
				start = (x - left) * step
				seg = arr[start:start + step]
				v = float(np.max(np.abs(seg))) if seg.size else 0.0
				draw.line((x, mid_y - int(v * 42), x, mid_y + int(v * 42)), fill=color)
		draw.line((left, mid_y, right, mid_y), fill=(36, 67, 76))
	out_path.parent.mkdir(parents=True, exist_ok=True)
	img.save(out_path)


def update_index(manifest_path: Path, sheet_path: Path) -> None:
	index = json.loads(INDEX_PATH.read_text())
	entry = {
		"path": "audio/sfx/sfx_hit_*.wav",
		"source": rel(manifest_path),
		"derived": rel(sheet_path),
		"reason": "Owner reported bullet impact sounds on zombies felt wrong. Rebuilt physical, fire, ice, lightning, poison, and immune hit SFX with distinct material signatures: metal/flesh thunk, hot fire pop/sizzle, brittle ice shatter, electric zap, corrosive splash, and shield ping while preserving existing IDs and runtime paths.",
		"count": len(FILES),
		"task": "elemental projectile hit SFX impact pass",
		"created_at": datetime.now(timezone.utc).isoformat(),
	}
	generated = index.setdefault("generated_replacements", [])
	generated = [item for item in generated if item.get("task") != entry["task"]]
	generated.append(entry)
	index["generated_replacements"] = generated
	INDEX_PATH.write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n")


def main() -> int:
	REF_DIR.mkdir(parents=True, exist_ok=True)
	backup_dir = REF_DIR / "original_hit_sfx"
	backup_dir.mkdir(parents=True, exist_ok=True)
	entries: list[dict] = []
	for element, filename in FILES.items():
		path = SFX_DIR / filename
		backup = backup_dir / filename
		if path.exists() and not backup.exists():
			shutil.copy2(path, backup)
		before = read_wav_metrics(backup if backup.exists() else path)
		after = write_wav(path, GENERATORS[element]())
		entries.append({
			"element": element,
			"file": filename,
			"original_backup": rel(backup),
			"old": before,
			"new": after,
		})

	manifest_path = REF_DIR / "hit_sfx_impact_manifest_2026_07_08.json"
	sheet_path = REF_DIR / "hit_sfx_impact_waveform_sheet_2026_07_08.png"
	manifest = {
		"id": "hit_sfx_impact_2026_07_08",
		"created_at": datetime.now(timezone.utc).isoformat(),
		"sample_rate": SR,
		"channels": 1,
		"design_note": "Projectile impacts are short, mobile-friendly, and differentiated by material: physical collision, fire pop/sizzle, ice crystal shatter, lightning crack, poison splash, and immune shield ping.",
		"entries": entries,
	}
	manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
	waveform_sheet(entries, sheet_path)
	update_index(manifest_path, sheet_path)
	for entry in entries:
		new = entry["new"]
		print(f"{entry['file']}: dur={new['duration_sec']:.3f}s peak={new['peak_dbfs']}dB rms={new['rms_dbfs']}dB L/M/H/A={new['low_ratio_60_350']}/{new['mid_ratio_350_2500']}/{new['high_ratio_2500_12000']}/{new['air_ratio_12000_18000']}")
	print(f"manifest: {rel(manifest_path)}")
	print(f"sheet: {rel(sheet_path)}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
