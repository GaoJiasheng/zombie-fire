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
REF_DIR = ROOT / "assets/production/source_refs/generated/weapon_sfx_realism_2026_07_07"
INDEX_PATH = ROOT / "assets/production/OUTSOURCER_ASSET_INDEX.json"
SR = 44100
TAU = math.tau
TARGET_PEAK = 10 ** (-4.2 / 20.0)
RNG = np.random.default_rng(20260707)


FILES = {
	"weapon_autocannon": "sfx_shot_autocannon.wav",
	"weapon_scattergun": "sfx_shot_scattergun.wav",
	"weapon_railgun": "sfx_shot_railgun.wav",
	"weapon_plasmacannon": "sfx_shot_plasmacannon.wav",
	"weapon_flamethrower": "sfx_shot_flamethrower.wav",
	"weapon_cryocannon": "sfx_shot_cryocannon.wav",
	"weapon_teslacoil": "sfx_shot_teslacoil.wav",
	"weapon_venomlauncher": "sfx_shot_venomlauncher.wav",
}

MUZZLE_FILES = {
	"muzzle_fire": "sfx_muzzle_fire.wav",
	"muzzle_ice": "sfx_muzzle_ice.wav",
	"muzzle_lightning": "sfx_muzzle_lightning.wav",
	"muzzle_poison": "sfx_muzzle_poison.wav",
}


def rel(path: Path) -> str:
	return path.relative_to(ROOT).as_posix()


def t(duration: float) -> np.ndarray:
	return np.arange(max(1, int(round(duration * SR))), dtype=np.float64) / SR


def empty(duration: float) -> np.ndarray:
	return np.zeros(max(1, int(round(duration * SR))), dtype=np.float64)


def env_decay(duration: float, tau: float, attack: float = 0.0008) -> np.ndarray:
	x = t(duration)
	out = np.exp(-x / max(tau, 0.001))
	a = min(len(out), max(1, int(round(attack * SR))))
	out[:a] *= np.linspace(0.0, 1.0, a) ** 0.7
	return out


def fade_tail(x: np.ndarray, seconds: float) -> np.ndarray:
	n = min(len(x), max(1, int(round(seconds * SR))))
	y = x.copy()
	y[-n:] *= np.linspace(1.0, 0.0, n) ** 1.4
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
	mask = (freqs >= low) & (freqs <= high)
	spec *= mask
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


def blast(duration: float, body_tau: float, low_gain: float, mid_gain: float, high_gain: float) -> np.ndarray:
	x = empty(duration)
	body = band_noise(duration, 120.0, 3600.0) * env_decay(duration, body_tau, 0.0005)
	crack = band_noise(duration, 2600.0, 12500.0) * env_decay(duration, body_tau * 0.42, 0.0003)
	thump = band_noise(duration, 55.0, 260.0) * env_decay(duration, body_tau * 0.82, 0.001)
	x += body * mid_gain
	x += crack * high_gain
	x += thump * low_gain
	return x


def muzzle_snap(duration: float = 0.028, gain: float = 1.0) -> np.ndarray:
	x = band_noise(duration, 1600.0, 15000.0) * env_decay(duration, 0.006, 0.0002)
	x += band_noise(duration, 450.0, 4200.0) * env_decay(duration, 0.009, 0.0002) * 0.4
	return x * gain


def mech_clack(duration: float = 0.052, bright: float = 1.0) -> np.ndarray:
	x = band_noise(duration, 900.0, 9200.0) * env_decay(duration, 0.018, 0.0008) * 0.55
	x += tone(1420.0, duration, RNG.random() * TAU) * env_decay(duration, 0.025, 0.001) * 0.16 * bright
	x += tone(2740.0, duration, RNG.random() * TAU) * env_decay(duration, 0.014, 0.001) * 0.10 * bright
	return x


def autocannon() -> np.ndarray:
	d = 0.145
	x = blast(d, 0.040, 0.34, 0.88, 0.78)
	add(x, muzzle_snap(0.024, 1.15), 0.0)
	add(x, mech_clack(0.050, 1.0), 0.030, 0.40)
	add(x, band_noise(0.046, 180.0, 1200.0) * env_decay(0.046, 0.018), 0.046, 0.22)
	return fade_tail(x, 0.034)


def scattergun() -> np.ndarray:
	d = 0.235
	x = blast(d, 0.075, 0.48, 0.82, 0.68)
	add(x, muzzle_snap(0.034, 1.05), 0.0)
	add(x, band_noise(0.090, 320.0, 5600.0) * env_decay(0.090, 0.045), 0.012, 0.50)
	add(x, mech_clack(0.070, 0.7), 0.092, 0.26)
	return fade_tail(x, 0.055)


def railgun() -> np.ndarray:
	d = 0.235
	x = empty(d)
	add(x, chirp(980.0, 2600.0, 0.060) * env_decay(0.060, 0.055, 0.002), 0.0, 0.25)
	add(x, blast(0.145, 0.038, 0.25, 0.72, 0.88), 0.050, 0.92)
	add(x, muzzle_snap(0.022, 1.25), 0.052)
	add(x, chirp(5200.0, 900.0, 0.130) * env_decay(0.130, 0.048, 0.0004), 0.060, 0.22)
	add(x, mech_clack(0.060, 1.1), 0.090, 0.25)
	return fade_tail(x, 0.045)


def plasmacannon() -> np.ndarray:
	d = 0.230
	x = empty(d)
	add(x, chirp(330.0, 880.0, 0.040) * env_decay(0.040, 0.040, 0.001), 0.0, 0.22)
	add(x, blast(0.170, 0.060, 0.22, 0.72, 0.76), 0.018, 0.88)
	add(x, muzzle_snap(0.030, 0.95), 0.020)
	add(x, chirp(1900.0, 520.0, 0.155) * env_decay(0.155, 0.055, 0.0005), 0.040, 0.22)
	return fade_tail(x, 0.055)


def flamethrower() -> np.ndarray:
	d = 0.245
	x = empty(d)
	add(x, band_noise(0.210, 170.0, 4700.0) * env_decay(0.210, 0.120, 0.004), 0.010, 0.80)
	add(x, band_noise(0.070, 2400.0, 9800.0) * env_decay(0.070, 0.030, 0.001), 0.0, 0.58)
	add(x, band_noise(0.060, 70.0, 330.0) * env_decay(0.060, 0.040, 0.001), 0.020, 0.20)
	add(x, mech_clack(0.045, 0.6), 0.025, 0.16)
	return fade_tail(x, 0.070)


def cryocannon() -> np.ndarray:
	d = 0.205
	x = empty(d)
	add(x, blast(0.130, 0.045, 0.18, 0.56, 0.84), 0.0, 0.72)
	for at, freq in [(0.010, 2900.0), (0.042, 4100.0), (0.081, 2300.0)]:
		add(x, tone(freq, 0.060, RNG.random() * TAU) * env_decay(0.060, 0.024, 0.0005), at, 0.18)
	add(x, band_noise(0.140, 1800.0, 12000.0) * env_decay(0.140, 0.052), 0.018, 0.30)
	return fade_tail(x, 0.045)


def teslacoil() -> np.ndarray:
	d = 0.185
	x = empty(d)
	add(x, blast(0.092, 0.030, 0.12, 0.46, 0.90), 0.0, 0.70)
	for at in [0.012, 0.044, 0.083]:
		zap = band_noise(0.055, 2400.0, 15000.0) * env_decay(0.055, 0.014, 0.0002)
		zap += chirp(6400.0, 1500.0, 0.055, RNG.random() * TAU) * env_decay(0.055, 0.018) * 0.22
		add(x, zap, at, 0.58)
	return fade_tail(x, 0.030)


def venomlauncher() -> np.ndarray:
	d = 0.225
	x = empty(d)
	add(x, blast(0.120, 0.052, 0.24, 0.56, 0.50), 0.0, 0.78)
	add(x, band_noise(0.150, 450.0, 6200.0) * env_decay(0.150, 0.070, 0.002), 0.030, 0.40)
	add(x, band_noise(0.060, 1700.0, 9500.0) * env_decay(0.060, 0.022), 0.004, 0.46)
	add(x, mech_clack(0.058, 0.65), 0.052, 0.18)
	return fade_tail(x, 0.055)


def muzzle_fire() -> np.ndarray:
	d = 0.140
	x = empty(d)
	add(x, band_noise(0.112, 260.0, 6200.0) * env_decay(0.112, 0.060, 0.001), 0.0, 0.72)
	add(x, band_noise(0.050, 3200.0, 13000.0) * env_decay(0.050, 0.018, 0.0002), 0.0, 0.46)
	add(x, band_noise(0.040, 80.0, 260.0) * env_decay(0.040, 0.025, 0.001), 0.010, 0.10)
	return fade_tail(x, 0.040)


def muzzle_ice() -> np.ndarray:
	d = 0.130
	x = empty(d)
	add(x, band_noise(0.105, 1200.0, 10500.0) * env_decay(0.105, 0.040, 0.0006), 0.0, 0.60)
	add(x, tone(3150.0, 0.060, RNG.random() * TAU) * env_decay(0.060, 0.022, 0.0004), 0.010, 0.18)
	add(x, chirp(1800.0, 620.0, 0.090) * env_decay(0.090, 0.050, 0.001), 0.020, 0.10)
	return fade_tail(x, 0.032)


def muzzle_lightning() -> np.ndarray:
	d = 0.120
	x = empty(d)
	for at in [0.0, 0.028, 0.058]:
		add(x, band_noise(0.052, 2500.0, 15000.0) * env_decay(0.052, 0.012, 0.0002), at, 0.56)
	add(x, chirp(6200.0, 1600.0, 0.090) * env_decay(0.090, 0.025, 0.0002), 0.004, 0.16)
	return fade_tail(x, 0.022)


def muzzle_poison() -> np.ndarray:
	d = 0.145
	x = empty(d)
	add(x, band_noise(0.120, 430.0, 7200.0) * env_decay(0.120, 0.058, 0.001), 0.0, 0.56)
	add(x, band_noise(0.080, 2200.0, 12000.0) * env_decay(0.080, 0.030, 0.0004), 0.006, 0.32)
	add(x, band_noise(0.045, 100.0, 310.0) * env_decay(0.045, 0.024, 0.001), 0.018, 0.08)
	return fade_tail(x, 0.040)


GENERATORS = {
	"weapon_autocannon": autocannon,
	"weapon_scattergun": scattergun,
	"weapon_railgun": railgun,
	"weapon_plasmacannon": plasmacannon,
	"weapon_flamethrower": flamethrower,
	"weapon_cryocannon": cryocannon,
	"weapon_teslacoil": teslacoil,
	"weapon_venomlauncher": venomlauncher,
	"muzzle_fire": muzzle_fire,
	"muzzle_ice": muzzle_ice,
	"muzzle_lightning": muzzle_lightning,
	"muzzle_poison": muzzle_poison,
}


def master(x: np.ndarray) -> np.ndarray:
	x = np.nan_to_num(x, copy=False)
	x -= float(np.mean(x)) if x.size else 0.0
	x = 0.72 * x + 0.28 * soft_clip(x * 2.8, 1.6)
	x = soft_clip(x, 2.15)
	x = norm(x, TARGET_PEAK)
	return np.clip(x, -0.985, 0.985)


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


def band_ratios(arr: np.ndarray, sr: int) -> tuple[float, float, float, float]:
	if arr.size < 2:
		return 0.0, 0.0, 0.0, 0.0
	window = np.hanning(arr.size)
	spec = np.abs(np.fft.rfft(arr * window)) ** 2
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


def waveform_sheet(entries: list[dict], out_path: Path) -> None:
	width = 1400
	row_h = 136
	height = 76 + row_h * len(entries)
	img = Image.new("RGB", (width, height), (9, 14, 18))
	draw = ImageDraw.Draw(img)
	try:
		font_title = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 28)
		font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 17)
	except OSError:
		font_title = ImageFont.load_default()
		font = ImageFont.load_default()
	draw.text((28, 22), "Weapon Shot SFX Realism Pass - waveform / spectrum guard", fill=(235, 240, 244), font=font_title)
	for i, entry in enumerate(entries):
		y = 72 + i * row_h
		draw.rectangle((26, y, width - 26, y + row_h - 16), outline=(70, 95, 108), fill=(13, 22, 27))
		path = ROOT / entry["new"]["path"]
		with wave.open(str(path), "rb") as wf:
			arr = np.frombuffer(wf.readframes(wf.getnframes()), dtype="<i2").astype(np.float64) / 32768.0
		left = 310
		top = y + 22
		right = width - 40
		mid_y = y + 70
		draw.text((42, y + 22), entry["weapon"], fill=(255, 213, 116), font=font)
		draw.text((42, y + 50), Path(entry["new"]["path"]).name, fill=(205, 224, 230), font=font)
		stats = entry["new"]
		draw.text((42, y + 78), f"{stats['duration_sec']:.3f}s  peak {stats['peak_dbfs']:.1f}  rms {stats['rms_dbfs']:.1f}", fill=(126, 156, 168), font=font)
		if arr.size:
			step = max(1, int(math.ceil(arr.size / (right - left))))
			pts = []
			for x in range(left, right):
				start = (x - left) * step
				seg = arr[start:start + step]
				v = float(np.max(np.abs(seg))) if seg.size else 0.0
				pts.append((x, mid_y - int(v * 42), x, mid_y + int(v * 42)))
			for x1, y1, x2, y2 in pts:
				draw.line((x1, y1, x2, y2), fill=(74, 214, 255))
		draw.line((left, mid_y, right, mid_y), fill=(36, 67, 76))
	out_path.parent.mkdir(parents=True, exist_ok=True)
	img.save(out_path)


def update_index(manifest_path: Path, sheet_path: Path) -> None:
	index = json.loads(INDEX_PATH.read_text())
	entry = {
		"path": "audio/sfx/sfx_shot_*.wav + audio/sfx/sfx_muzzle_*.wav",
		"source": rel(manifest_path),
		"derived": rel(sheet_path),
		"reason": "Owner said the gunfire sounded like a frog croak. Rebuilt all weapon shot and elemental muzzle SFX as broadband transient firearm/energy-weapon sounds with mechanical snap and reduced low-frequency tonal dominance while preserving existing IDs and paths.",
		"count": len(FILES) + len(MUZZLE_FILES),
		"task": "weapon shot SFX realism pass",
		"created_at": datetime.now(timezone.utc).isoformat(),
	}
	generated = index.setdefault("generated_replacements", [])
	generated = [item for item in generated if item.get("task") != entry["task"]]
	generated.append(entry)
	index["generated_replacements"] = generated
	INDEX_PATH.write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n")


def main() -> int:
	REF_DIR.mkdir(parents=True, exist_ok=True)
	backup_dir = REF_DIR / "original_weapon_shots"
	backup_dir.mkdir(parents=True, exist_ok=True)
	entries: list[dict] = []
	items = list(FILES.items()) + list(MUZZLE_FILES.items())
	for weapon, filename in items:
		path = SFX_DIR / filename
		backup = backup_dir / filename
		if path.exists() and not backup.exists():
			shutil.copy2(path, backup)
		before = read_wav_metrics(backup if backup.exists() else path)
		after = write_wav(path, GENERATORS[weapon]())
		entries.append({
			"weapon": weapon,
			"file": filename,
			"original_backup": rel(backup),
			"old": before,
			"new": after,
		})

	manifest_path = REF_DIR / "weapon_sfx_realism_manifest_2026_07_07.json"
	sheet_path = REF_DIR / "weapon_sfx_realism_waveform_sheet_2026_07_07.png"
	manifest = {
		"id": "weapon_sfx_realism_2026_07_07",
		"created_at": datetime.now(timezone.utc).isoformat(),
		"sample_rate": SR,
		"channels": 1,
		"design_note": "Replace low-frequency tonal/croaking shot and muzzle sounds with short broadband firearm-like transients, mechanical clack, and weapon-specific air/energy tails.",
		"entries": entries,
	}
	manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
	waveform_sheet(entries, sheet_path)
	update_index(manifest_path, sheet_path)
	for entry in entries:
		new = entry["new"]
		print(f"{entry['file']}: dur={new['duration_sec']:.3f}s peak={new['peak_dbfs']}dB rms={new['rms_dbfs']}dB low={new['low_ratio_60_350']} high={new['high_ratio_2500_12000']}")
	print(f"manifest: {rel(manifest_path)}")
	print(f"sheet: {rel(sheet_path)}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
