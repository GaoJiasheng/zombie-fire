#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import math
import wave
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


SR = 44100
ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets/production/audio/sfx"
REF_DIR = ROOT / "assets/production/source_refs/generated/sfx_expansion_2026_07_05"
RNG = np.random.default_rng(20260705)
TARGET_PEAK_DB = -4.7
TARGET_PEAK = 10 ** (TARGET_PEAK_DB / 20.0)


def _time(duration: float) -> np.ndarray:
	return np.arange(max(1, int(round(duration * SR))), dtype=np.float64) / SR


def _empty(duration: float) -> np.ndarray:
	return np.zeros(max(1, int(round(duration * SR))), dtype=np.float64)


def _tone(freq: float, duration: float, phase: float = 0.0) -> np.ndarray:
	t = _time(duration)
	return np.sin(TAU * freq * t + phase)


TAU = math.tau


def _chirp(start: float, end: float, duration: float, phase: float = 0.0) -> np.ndarray:
	t = _time(duration)
	k = (end - start) / max(duration, 0.001)
	return np.sin(TAU * (start * t + 0.5 * k * t * t) + phase)


def _env(duration: float, attack: float = 0.01, release: float = 0.05, curve: float = 1.6) -> np.ndarray:
	n = max(1, int(round(duration * SR)))
	out = np.ones(n, dtype=np.float64)
	a = min(n, max(1, int(round(attack * SR))))
	r = min(n, max(1, int(round(release * SR))))
	out[:a] = np.linspace(0.0, 1.0, a) ** curve
	out[-r:] *= np.linspace(1.0, 0.0, r) ** curve
	return out


def _decay(duration: float, tau: float = 0.12, attack: float = 0.002) -> np.ndarray:
	t = _time(duration)
	out = np.exp(-t / max(tau, 0.001))
	a = min(len(out), max(1, int(round(attack * SR))))
	out[:a] *= np.linspace(0.0, 1.0, a)
	return out


def _band_noise(duration: float, low: float, high: float) -> np.ndarray:
	n = max(2, int(round(duration * SR)))
	noise = RNG.normal(0.0, 1.0, n)
	spec = np.fft.rfft(noise)
	freqs = np.fft.rfftfreq(n, 1.0 / SR)
	mask = (freqs >= low) & (freqs <= high)
	spec *= mask
	out = np.fft.irfft(spec, n)
	return _norm(out)


def _low_noise(duration: float) -> np.ndarray:
	return _band_noise(duration, 35.0, 280.0)


def _hi_noise(duration: float) -> np.ndarray:
	return _band_noise(duration, 1800.0, 9600.0)


def _norm(x: np.ndarray, peak: float = 1.0) -> np.ndarray:
	m = float(np.max(np.abs(x))) if x.size else 0.0
	if m < 1e-9:
		return x
	return x / m * peak


def _add(dst: np.ndarray, src: np.ndarray, at: float, gain: float = 1.0) -> None:
	start = int(round(at * SR))
	if start >= len(dst):
		return
	end = min(len(dst), start + len(src))
	if end > start:
		dst[start:end] += src[: end - start] * gain


def _soft_clip(x: np.ndarray, drive: float = 1.0) -> np.ndarray:
	return np.tanh(x * drive) / math.tanh(drive)


def _delay(x: np.ndarray, seconds: float, feedback: float = 0.22, mix: float = 0.22) -> np.ndarray:
	d = max(1, int(round(seconds * SR)))
	out = np.copy(x)
	for i in range(d, len(out)):
		out[i] += out[i - d] * feedback
	return x * (1.0 - mix) + out * mix


def _master(x: np.ndarray, peak_db: float = TARGET_PEAK_DB) -> np.ndarray:
	x = np.nan_to_num(x, copy=False)
	x = _soft_clip(x, 1.35)
	peak = 10 ** (peak_db / 20.0)
	x = _norm(x, peak)
	return np.clip(x, -0.985, 0.985)


def _write_wav(path: Path, x: np.ndarray) -> dict:
	path.parent.mkdir(parents=True, exist_ok=True)
	y = _master(x)
	pcm = (y * 32767.0).astype("<i2")
	with wave.open(str(path), "wb") as wf:
		wf.setnchannels(1)
		wf.setsampwidth(2)
		wf.setframerate(SR)
		wf.writeframes(pcm.tobytes())
	peak = float(np.max(np.abs(y))) if y.size else 0.0
	rms = float(np.sqrt(np.mean(y * y))) if y.size else 0.0
	return {
		"path": str(path.relative_to(ROOT)),
		"duration_sec": round(len(y) / SR, 3),
		"sample_rate": SR,
		"channels": 1,
		"peak_dbfs": round(20 * math.log10(max(peak, 1e-9)), 2),
		"rms_dbfs": round(20 * math.log10(max(rms, 1e-9)), 2),
		"sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
	}


def _click(duration: float = 0.055, freq: float = 1600.0, noise_low: float = 1200.0, noise_high: float = 7000.0) -> np.ndarray:
	x = _tone(freq, duration) * _decay(duration, 0.025)
	x += _band_noise(duration, noise_low, noise_high) * _decay(duration, 0.018) * 0.7
	return x


def _impact(duration: float = 0.28, thump_freq: float = 80.0, metal_freq: float = 720.0) -> np.ndarray:
	x = _tone(thump_freq, duration) * _decay(duration, 0.11) * 0.9
	for f, g in [(metal_freq, 0.42), (metal_freq * 1.63, 0.26), (metal_freq * 2.17, 0.14)]:
		x += _tone(f, duration, RNG.random() * TAU) * _decay(duration, 0.08) * g
	x += _band_noise(duration, 120.0, 2400.0) * _decay(duration, 0.06) * 0.42
	return x


def _whoosh(duration: float = 0.42, high: bool = True) -> np.ndarray:
	t = _time(duration)
	base = _band_noise(duration, 500.0 if high else 90.0, 7200.0 if high else 1500.0)
	sweep = np.sin(np.linspace(0, math.pi, len(base))) ** 1.4
	return base * sweep


def _fire_burst(duration: float = 0.42) -> np.ndarray:
	x = _band_noise(duration, 55.0, 2200.0) * _decay(duration, 0.18) * 0.75
	x += _hi_noise(duration) * _decay(duration, 0.09) * 0.34
	x += _tone(63.0, duration) * _decay(duration, 0.13) * 0.7
	return _soft_clip(x, 1.8)


def _ice_crack(duration: float = 0.28) -> np.ndarray:
	x = _empty(duration)
	for at, f, g in [(0.0, 2300.0, 0.9), (0.025, 3300.0, 0.58), (0.064, 1800.0, 0.4)]:
		_add(x, _click(0.105, f, 2200.0, 11000.0), at, g)
	x += _chirp(1200.0, 360.0, duration) * _decay(duration, 0.18) * 0.18
	return x


def _electric_arc(duration: float = 0.28, pulses: int = 3) -> np.ndarray:
	x = _empty(duration)
	for i in range(pulses):
		at = 0.012 + i * duration / max(pulses + 1, 2) + float(RNG.uniform(-0.006, 0.006))
		zap = _band_noise(0.075, 1600.0, 13000.0) * _decay(0.075, 0.022)
		zap += _chirp(5200.0, 1300.0, 0.075, RNG.random() * TAU) * _decay(0.075, 0.035) * 0.35
		_add(x, zap, at, 0.9)
	return _soft_clip(x, 2.0)


def _wet(duration: float = 0.4) -> np.ndarray:
	x = _band_noise(duration, 110.0, 1100.0) * _env(duration, 0.004, 0.12) * 0.65
	for at in np.linspace(0.02, duration - 0.1, 4):
		bub = _chirp(float(RNG.uniform(180, 360)), float(RNG.uniform(70, 120)), 0.12) * _decay(0.12, 0.055)
		_add(x, bub, float(at), 0.6)
	return _soft_clip(x, 1.6)


def skill_split_shot() -> np.ndarray:
	x = _empty(0.18)
	_add(x, _click(0.07, 1900.0), 0.0, 0.8)
	_add(x, _click(0.055, 2650.0), 0.038, 0.45)
	_add(x, _click(0.05, 3100.0), 0.072, 0.28)
	return _delay(x, 0.045, 0.2, 0.18)


def skill_pierce() -> np.ndarray:
	x = _impact(0.18, 92.0, 480.0) * 0.9
	x += _whoosh(0.18, False) * _decay(0.18, 0.08) * 0.32
	return x


def skill_multishot() -> np.ndarray:
	x = _empty(0.13)
	for i, at in enumerate([0.0, 0.026, 0.049]):
		_add(x, _click(0.055, 1100.0 + i * 180.0, 900.0, 6200.0), at, 0.65 - i * 0.08)
	return x


def skill_slow_field() -> np.ndarray:
	d = 0.36
	t = _time(d)
	x = _chirp(170.0, 58.0, d) * _env(d, 0.025, 0.12) * 0.72
	x += _band_noise(d, 85.0, 500.0) * _env(d, 0.02, 0.14) * 0.22
	x += np.sin(TAU * (8.0 * t)) * _env(d, 0.02, 0.09) * 0.12
	return x


def skill_homing() -> np.ndarray:
	x = _chirp(850.0, 1460.0, 0.13) * _env(0.13, 0.006, 0.035) * 0.65
	_add(x, _click(0.045, 2200.0), 0.012, 0.32)
	return x


def skill_critical() -> np.ndarray:
	x = _impact(0.26, 72.0, 840.0) * 0.9
	_add(x, _click(0.12, 2600.0, 1700.0, 9800.0), 0.01, 0.45)
	return _delay(x, 0.035, 0.18, 0.2)


def skill_barrier() -> np.ndarray:
	d = 0.34
	x = _chirp(220.0, 760.0, d) * _env(d, 0.012, 0.06) * 0.58
	x += _chirp(520.0, 1700.0, d) * _env(d, 0.03, 0.05) * 0.25
	x += _band_noise(d, 2400.0, 9000.0) * _env(d, 0.04, 0.05) * 0.12
	return x


def skill_gold_rush() -> np.ndarray:
	x = _empty(0.24)
	for at in [0.0, 0.018, 0.041, 0.079, 0.116]:
		_add(x, _click(0.085, float(RNG.uniform(1850, 3600)), 1600.0, 9000.0), at, float(RNG.uniform(0.22, 0.48)))
	return _delay(x, 0.028, 0.26, 0.18)


def skill_ricochet() -> np.ndarray:
	x = _chirp(1640.0, 2140.0, 0.11) * _decay(0.11, 0.04) * 0.75
	_add(x, _click(0.055, 2800.0), 0.008, 0.35)
	return x


def skill_salvo() -> np.ndarray:
	x = _empty(0.24)
	for i, at in enumerate([0.0, 0.045, 0.086, 0.125, 0.162]):
		_add(x, _click(0.058, 680.0 + i * 70.0, 320.0, 3900.0), at, 0.45)
	x += _chirp(120.0, 340.0, 0.24) * _env(0.24, 0.02, 0.05) * 0.22
	return x


def skill_incendiary() -> np.ndarray:
	x = _empty(0.24)
	_add(x, _click(0.06, 900.0, 700.0, 5400.0), 0.0, 0.45)
	x += _band_noise(0.24, 600.0, 7200.0) * _env(0.24, 0.015, 0.09) * 0.48
	_add(x, _fire_burst(0.2), 0.015, 0.28)
	return x


def skill_cryo() -> np.ndarray:
	return _ice_crack(0.2)


def skill_tesla() -> np.ndarray:
	return _electric_arc(0.24, 4)


def skill_venom() -> np.ndarray:
	return _wet(0.22)


def skill_charge_shot_charge() -> np.ndarray:
	d = 0.82
	t = _time(d)
	x = (_tone(86.0, d) * 0.36 + _tone(173.0, d) * 0.18)
	x *= (0.82 + 0.18 * np.sin(TAU * 5.0 * t))
	x += _band_noise(d, 90.0, 700.0) * 0.12
	return x * _env(d, 0.035, 0.04)


def skill_charge_shot_release() -> np.ndarray:
	x = _impact(0.2, 58.0, 650.0)
	x += _whoosh(0.2, False) * 0.25
	return x


def skill_recycle() -> np.ndarray:
	x = _empty(0.25)
	_add(x, _whoosh(0.19, True), 0.0, 0.38)
	for at in [0.035, 0.084, 0.133]:
		_add(x, _click(0.06, 1280.0, 800.0, 7000.0), at, 0.35)
	x += _chirp(420.0, 780.0, 0.25) * _env(0.25, 0.02, 0.06) * 0.22
	return x


def char_intro(kind: str) -> np.ndarray:
	d = 0.56
	x = _band_noise(d, 140.0, 1100.0) * _env(d, 0.03, 0.2) * 0.25
	if kind == "vanguard":
		_add(x, _click(0.09, 560.0, 260.0, 4200.0), 0.03, 0.8)
		_add(x, _click(0.08, 900.0, 440.0, 5200.0), 0.15, 0.45)
		x += _tone(96.0, d) * _env(d, 0.02, 0.18) * 0.18
	elif kind == "blaze":
		_add(x, _fire_burst(0.28), 0.16, 0.55)
		x += _chirp(220.0, 330.0, d) * _env(d, 0.02, 0.16) * 0.16
	elif kind == "frost":
		_add(x, _ice_crack(0.18), 0.18, 0.65)
		x += _band_noise(d, 900.0, 5000.0) * _env(d, 0.02, 0.18) * 0.12
	elif kind == "volt":
		_add(x, _electric_arc(0.16, 2), 0.22, 0.8)
		x += _chirp(520.0, 1180.0, d) * _env(d, 0.02, 0.15) * 0.15
	return x


def sig_vanguard_railvolley() -> np.ndarray:
	d = 5.35
	x = _band_noise(d, 42.0, 260.0) * _env(d, 0.06, 0.4) * 0.18
	times = [0.26, 0.82, 1.30, 1.72, 2.08, 2.42, 2.73, 3.02, 3.30, 3.56, 3.82, 4.08, 4.34]
	for i, at in enumerate(times):
		burst = _impact(0.34, 54.0 + i * 1.7, 420.0 + i * 12.0)
		burst += _band_noise(0.34, 80.0, 3500.0) * _decay(0.34, 0.08) * 0.42
		_add(x, burst, at, 0.72 + min(i, 6) * 0.035)
	x = _delay(x, 0.095, 0.2, 0.28)
	return x


def sig_blaze_meltdown() -> np.ndarray:
	d = 3.72
	x = _band_noise(d, 90.0, 800.0) * _env(d, 0.05, 0.38) * 0.12
	for i, at in enumerate([0.18, 1.02, 1.88, 2.76]):
		_add(x, _fire_burst(0.68), at, 0.76 + i * 0.06)
		_add(x, _impact(0.32, 49.0, 360.0), at + 0.02, 0.45)
	return _delay(x, 0.12, 0.18, 0.22)


def sig_frost_glacier() -> np.ndarray:
	d = 5.08
	x = _band_noise(d, 110.0, 1200.0) * _env(d, 0.08, 0.45) * 0.22
	x += _chirp(480.0, 185.0, d) * _env(d, 0.12, 0.45) * 0.2
	for i, at in enumerate([0.42, 1.55, 2.68, 3.82]):
		_add(x, _ice_crack(0.52), at, 0.68 + i * 0.08)
	return _delay(x, 0.16, 0.16, 0.2)


def sig_volt_storm() -> np.ndarray:
	d = 1.82
	x = _empty(d)
	_add(x, _impact(0.38, 68.0, 950.0), 0.02, 0.72)
	_add(x, _electric_arc(0.55, 7), 0.06, 1.0)
	for at in [0.5, 0.72, 0.96, 1.24]:
		_add(x, _electric_arc(0.3, 4), at, 0.55)
	return _delay(x, 0.065, 0.22, 0.24)


def zombie_screamer() -> np.ndarray:
	d = 0.92
	x = _chirp(880.0, 520.0, d) * _env(d, 0.04, 0.22) * 0.48
	x += _band_noise(d, 700.0, 3800.0) * _env(d, 0.02, 0.26) * 0.38
	x += _tone(112.0, d) * _env(d, 0.03, 0.2) * 0.17
	return _delay(x, 0.11, 0.18, 0.25)


def zombie_spitter() -> np.ndarray:
	x = _empty(0.62)
	_add(x, _wet(0.18), 0.0, 0.85)
	x += _band_noise(0.62, 1600.0, 8200.0) * _env(0.62, 0.02, 0.18) * 0.35
	return x


def zombie_shielder() -> np.ndarray:
	d = 1.18
	x = _tone(96.0, d) * _env(d, 0.08, 0.24) * 0.34
	x += _chirp(180.0, 260.0, d) * _env(d, 0.08, 0.28) * 0.18
	x += _band_noise(d, 300.0, 1400.0) * _env(d, 0.05, 0.24) * 0.12
	return x


def zombie_hopper() -> np.ndarray:
	x = _empty(0.78)
	_add(x, _whoosh(0.28, True), 0.02, 0.48)
	_add(x, _impact(0.32, 72.0, 430.0), 0.43, 0.8)
	return x


def zombie_juggernaut() -> np.ndarray:
	x = _empty(1.16)
	for at in [0.06, 0.46, 0.84]:
		_add(x, _impact(0.32, 42.0, 300.0), at, 0.72)
	return x


def zombie_phantom() -> np.ndarray:
	d = 0.58
	x = _empty(d)
	_add(x, _electric_arc(0.4, 4), 0.0, 0.5)
	x += _chirp(1100.0, 120.0, d) * _env(d, 0.01, 0.2) * 0.36
	x += _band_noise(d, 1400.0, 9500.0) * _env(d, 0.015, 0.18) * 0.18
	return _delay(x, 0.043, 0.28, 0.22)


def zombie_necromancer() -> np.ndarray:
	d = 1.04
	x = _tone(88.0, d) * _env(d, 0.06, 0.3) * 0.25
	x += _band_noise(d, 110.0, 900.0) * _env(d, 0.06, 0.28) * 0.28
	_add(x, _wet(0.24), 0.64, 0.65)
	return x


def zombie_toxic() -> np.ndarray:
	d = 1.36
	x = _band_noise(d, 1200.0, 9200.0) * _env(d, 0.08, 0.34) * 0.5
	x += _wet(d) * 0.22
	return x


def zombie_charger() -> np.ndarray:
	x = _empty(1.14)
	for i, at in enumerate([0.03, 0.21, 0.36, 0.49, 0.6]):
		_add(x, _impact(0.17, 58.0, 360.0), at, 0.34 + i * 0.05)
	_add(x, _impact(0.36, 48.0, 420.0), 0.76, 0.92)
	return x


def zombie_regenerator() -> np.ndarray:
	return _wet(0.9)


def zombie_splitter() -> np.ndarray:
	x = _empty(0.66)
	_add(x, _wet(0.18), 0.0, 0.8)
	_add(x, _wet(0.13), 0.24, 0.38)
	_add(x, _wet(0.13), 0.36, 0.34)
	return x


def zombie_warden() -> np.ndarray:
	d = 1.34
	x = _tone(62.0, d) * _env(d, 0.06, 0.34) * 0.38
	x += _chirp(120.0, 86.0, d) * _env(d, 0.08, 0.38) * 0.27
	x += _band_noise(d, 160.0, 900.0) * _env(d, 0.05, 0.32) * 0.14
	return _delay(x, 0.18, 0.13, 0.22)


def zombie_mutant() -> np.ndarray:
	x = _empty(0.88)
	for at in [0.02, 0.11, 0.22, 0.31]:
		_add(x, _click(0.07, float(RNG.uniform(430, 1100)), 300.0, 5200.0), at, 0.5)
	x += _band_noise(0.88, 90.0, 1200.0) * _env(0.88, 0.2, 0.26) * 0.38
	return x


def zombie_berserker() -> np.ndarray:
	x = _band_noise(0.92, 100.0, 1400.0) * _env(0.92, 0.05, 0.24) * 0.42
	for at in [0.24, 0.46, 0.64]:
		_add(x, _impact(0.18, 54.0, 240.0), at, 0.36)
	return x


def zombie_runner() -> np.ndarray:
	x = _empty(0.68)
	for i, at in enumerate([0.0, 0.09, 0.17, 0.245, 0.315, 0.38, 0.445, 0.505]):
		_add(x, _click(0.048, 520.0, 220.0, 3500.0), at, 0.32 + i * 0.015)
	return x


def zombie_bomber() -> np.ndarray:
	x = _empty(1.2)
	x += _band_noise(1.2, 1800.0, 9000.0) * _env(1.2, 0.08, 0.24) * 0.24
	_add(x, _fire_burst(0.42), 0.78, 0.92)
	_add(x, _impact(0.34, 45.0, 340.0), 0.78, 0.66)
	return x


def zombie_shambler() -> np.ndarray:
	d = 0.82
	x = _band_noise(d, 90.0, 850.0) * _env(d, 0.06, 0.28) * 0.32
	_add(x, _click(0.08, 360.0, 180.0, 2300.0), 0.3, 0.24)
	return x


def zombie_brute() -> np.ndarray:
	x = _empty(0.92)
	_add(x, _impact(0.28, 48.0, 260.0), 0.08, 0.62)
	_add(x, _impact(0.28, 52.0, 300.0), 0.48, 0.56)
	return x


def zombie_armored() -> np.ndarray:
	x = _impact(0.46, 74.0, 980.0)
	_add(x, _click(0.12, 2200.0, 1200.0, 8000.0), 0.018, 0.42)
	return x


def zombie_crawler() -> np.ndarray:
	d = 0.72
	x = _band_noise(d, 300.0, 4200.0) * _env(d, 0.04, 0.24) * 0.34
	x += _wet(d) * 0.18
	return x


ASSETS = {
	"sfx_skill_split_shot.wav": (skill_split_shot, "skill trigger: split bullet crack with short echo"),
	"sfx_skill_pierce.wav": (skill_pierce, "skill trigger: heavy piercing thud"),
	"sfx_skill_multishot.wav": (skill_multishot, "skill trigger: layered multishot echo"),
	"sfx_skill_slow_field.wav": (skill_slow_field, "skill trigger: low pitch-bent slow field pulse"),
	"sfx_skill_homing.wav": (skill_homing, "skill trigger: light radar lock beep"),
	"sfx_skill_critical.wav": (skill_critical, "skill trigger: heavy metallic critical hit"),
	"sfx_skill_barrier.wav": (skill_barrier, "skill trigger: rising shield charge"),
	"sfx_skill_gold_rush.wav": (skill_gold_rush, "skill trigger: richer coin scatter"),
	"sfx_skill_ricochet.wav": (skill_ricochet, "skill trigger: short ricochet ping"),
	"sfx_skill_salvo.wav": (skill_salvo, "skill trigger: rapid mechanical reload"),
	"sfx_skill_incendiary.wav": (skill_incendiary, "skill trigger: ignition hiss and crackle"),
	"sfx_skill_cryo.wav": (skill_cryo, "skill trigger: sharp ice crack"),
	"sfx_skill_tesla.wav": (skill_tesla, "skill trigger: chained high-voltage arcs"),
	"sfx_skill_venom.wav": (skill_venom, "skill trigger: corrosive bubble pop"),
	"sfx_skill_charge_shot_charge.wav": (skill_charge_shot_charge, "skill trigger: loopable low charge hum"),
	"sfx_skill_charge_shot_release.wav": (skill_charge_shot_release, "skill trigger: charged heavy release"),
	"sfx_skill_recycle.wav": (skill_recycle, "skill trigger: tactical card recycle swipe"),
	"sfx_char_vanguard_intro.wav": (lambda: char_intro("vanguard"), "character intro: veteran reload and breath"),
	"sfx_sig_vanguard_railvolley.wav": (sig_vanguard_railvolley, "signature skill: accelerating heavy rail volley"),
	"sfx_char_blaze_intro.wav": (lambda: char_intro("blaze"), "character intro: hot-blooded breath and flame"),
	"sfx_sig_blaze_meltdown.wav": (sig_blaze_meltdown, "signature skill: four molten blast pulses"),
	"sfx_char_frost_intro.wav": (lambda: char_intro("frost"), "character intro: cold breath and ice shard"),
	"sfx_sig_frost_glacier.wav": (sig_frost_glacier, "signature skill: glacier field expansion with four cracks"),
	"sfx_char_volt_intro.wav": (lambda: char_intro("volt"), "character intro: lively breath and arc snap"),
	"sfx_sig_volt_storm.wav": (sig_volt_storm, "signature skill: main thunder strike and branching arcs"),
	"sfx_zombie_screamer.wav": (zombie_screamer, "zombie mechanic: buff aura scream"),
	"sfx_zombie_spitter.wav": (zombie_spitter, "zombie mechanic: acid spit"),
	"sfx_zombie_shielder.wav": (zombie_shielder, "zombie mechanic: shield aura hum"),
	"sfx_zombie_hopper.wav": (zombie_hopper, "zombie mechanic: leap and landing"),
	"sfx_zombie_juggernaut.wav": (zombie_juggernaut, "zombie mechanic: heavy stomps"),
	"sfx_zombie_phantom.wav": (zombie_phantom, "zombie mechanic: phase blink glitch"),
	"sfx_zombie_necromancer.wav": (zombie_necromancer, "zombie mechanic: summon chant and spawn"),
	"sfx_zombie_toxic.wav": (zombie_toxic, "zombie mechanic: toxic gas leak"),
	"sfx_zombie_charger.wav": (zombie_charger, "zombie mechanic: accelerating charge and impact"),
	"sfx_zombie_regenerator.wav": (zombie_regenerator, "zombie mechanic: wet regeneration"),
	"sfx_zombie_splitter.wav": (zombie_splitter, "zombie mechanic: death split and small landings"),
	"sfx_zombie_warden.wav": (zombie_warden, "zombie mechanic: heavy ward pulse"),
	"sfx_zombie_mutant.wav": (zombie_mutant, "zombie mechanic: bone mutation and growl"),
	"sfx_zombie_berserker.wav": (zombie_berserker, "zombie mechanic: rage roar and heartbeat"),
	"sfx_zombie_runner.wav": (zombie_runner, "zombie mechanic: rapid sprint steps"),
	"sfx_zombie_bomber.wav": (zombie_bomber, "zombie mechanic: fuse and death blast"),
	"sfx_zombie_shambler.wav": (zombie_shambler, "zombie mechanic: baseline shambler groan"),
	"sfx_zombie_brute.wav": (zombie_brute, "zombie mechanic: heavy brute steps"),
	"sfx_zombie_armored.wav": (zombie_armored, "zombie mechanic: metal partial block"),
	"sfx_zombie_crawler.wav": (zombie_crawler, "zombie mechanic: ground crawl scrape"),
}


def _make_sheet(records: list[dict]) -> None:
	cell_w, cell_h = 430, 96
	cols = 3
	rows = math.ceil(len(records) / cols)
	img = Image.new("RGB", (cols * cell_w, rows * cell_h), (12, 16, 20))
	draw = ImageDraw.Draw(img)
	try:
		font = ImageFont.truetype("Arial.ttf", 14)
	except Exception:
		font = ImageFont.load_default()
	for idx, rec in enumerate(records):
		x0 = (idx % cols) * cell_w
		y0 = (idx // cols) * cell_h
		draw.rectangle([x0 + 8, y0 + 8, x0 + cell_w - 8, y0 + cell_h - 8], outline=(70, 88, 104), width=1)
		draw.text((x0 + 14, y0 + 12), Path(rec["path"]).name, fill=(224, 232, 238), font=font)
		draw.text((x0 + 14, y0 + 32), f'{rec["duration_sec"]:.2f}s  peak {rec["peak_dbfs"]:.1f} dB', fill=(146, 170, 184), font=font)
		with wave.open(str(ROOT / rec["path"]), "rb") as wf:
			raw = wf.readframes(wf.getnframes())
		data = np.frombuffer(raw, dtype="<i2").astype(np.float64) / 32767.0
		if len(data) == 0:
			continue
		wave_x0, wave_y0 = x0 + 14, y0 + 56
		wave_w, wave_h = cell_w - 28, 28
		samples = np.interp(np.linspace(0, len(data) - 1, wave_w), np.arange(len(data)), data)
		center = wave_y0 + wave_h // 2
		color = (255, 170, 55) if "fire" in rec["path"] or "blaze" in rec["path"] or "zombie_bomber" in rec["path"] else (86, 218, 235)
		for i, v in enumerate(samples):
			y = int(center - v * wave_h * 0.48)
			draw.line([wave_x0 + i, center, wave_x0 + i, y], fill=color)
	img.save(REF_DIR / "sfx_expansion_waveform_sheet_2026_07_05.png")


def main() -> None:
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	REF_DIR.mkdir(parents=True, exist_ok=True)
	records: list[dict] = []
	for filename, (factory, description) in ASSETS.items():
		path = OUT_DIR / filename
		audio = factory()
		record = _write_wav(path, audio)
		record["description"] = description
		records.append(record)
	_make_sheet(records)
	manifest = {
		"generated_at": "2026-07-05",
		"source_doc": "design/sfx_expansion_prompts_2026_07_05.md",
		"generator": "tools/generate_sfx_expansion_2026_07_05.py",
		"render_method": "local procedural synthesis, deterministic seed 20260705",
		"technical_spec": {
			"format": "WAV",
			"codec": "pcm_s16le",
			"sample_rate": SR,
			"channels": 1,
			"target_peak_dbfs": TARGET_PEAK_DB,
		},
		"outputs": records,
		"contact_sheet": "assets/production/source_refs/generated/sfx_expansion_2026_07_05/sfx_expansion_waveform_sheet_2026_07_05.png",
	}
	(REF_DIR / "sfx_expansion_manifest_2026_07_05.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
	print(f"generated {len(records)} sfx files")
	print(REF_DIR / "sfx_expansion_manifest_2026_07_05.json")


if __name__ == "__main__":
	main()
