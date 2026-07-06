#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import sys
import wave
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
SEQ_DIR = PROD / "sprites" / "vfx_sequences"
AUDIO_DIR = PROD / "audio" / "sfx"


EXPECTED_SEQUENCES = {
	"vfx_hit_fire": 12,
	"vfx_explosion_fire": 16,
	"vfx_active_sig_vanguard_railvolley": 14,
	"vfx_active_sig_vanguard_overload": 14,
	"vfx_active_sig_blaze_meltdown": 14,
	"vfx_active_sig_frost_glacier": 14,
	"vfx_active_sig_volt_storm": 14,
}

ACTIVE_SFX = {
	"sfx_sig_vanguard_railvolley.wav": (1.2, 6.0),
	"sfx_sig_blaze_meltdown.wav": (1.0, 5.5),
	"sfx_sig_frost_glacier.wav": (1.2, 6.0),
	"sfx_sig_volt_storm.wav": (0.8, 4.0),
}


def sequence_json(sequence_id: str) -> Path:
	return SEQ_DIR / sequence_id / f"{sequence_id}_sequence.json"


def frame_paths(sequence_id: str) -> list[Path]:
	data = json.loads(sequence_json(sequence_id).read_text())
	return [PROD / str(frame) for frame in data.get("frames", [])]


def image_alpha_metrics(path: Path) -> dict[str, float]:
	img = Image.open(path).convert("RGBA")
	alpha = np.asarray(img.getchannel("A"), dtype=np.float32)
	h, w = alpha.shape
	border = np.concatenate([alpha[0, :], alpha[-1, :], alpha[:, 0], alpha[:, -1]])
	mask = alpha > 24
	if not np.any(mask):
		return {"edge_max": float(border.max()), "centroid_x": 0.5, "centroid_y": 0.5, "coverage": 0.0, "bbox_w": 0.0, "bbox_h": 0.0}
	yy, xx = np.mgrid[0:h, 0:w]
	weights = alpha * mask
	total = float(weights.sum())
	ys, xs = np.where(mask)
	return {
		"edge_max": float(border.max()),
		"centroid_x": float((xx * weights).sum() / total / max(w - 1, 1)),
		"centroid_y": float((yy * weights).sum() / total / max(h - 1, 1)),
		"coverage": float(mask.mean()),
		"bbox_w": float((xs.max() - xs.min() + 1) / max(w, 1)),
		"bbox_h": float((ys.max() - ys.min() + 1) / max(h, 1)),
	}


def wav_metrics(path: Path) -> dict[str, float]:
	with wave.open(str(path), "rb") as wf:
		sr = wf.getframerate()
		channels = wf.getnchannels()
		frames = wf.getnframes()
		data = wf.readframes(frames)
	if channels != 1:
		raise ValueError(f"{path.relative_to(ROOT)} must be mono for predictable mobile mix")
	arr = np.frombuffer(data, dtype="<i2").astype(np.float64) / 32768.0
	peak = float(np.max(np.abs(arr))) if arr.size else 0.0
	rms = float(np.sqrt(np.mean(arr * arr))) if arr.size else 0.0
	return {
		"duration": frames / sr,
		"peak_db": 20.0 * math.log10(max(peak, 1e-9)),
		"rms_db": 20.0 * math.log10(max(rms, 1e-9)),
		"sample_rate": float(sr),
	}


def main() -> int:
	errors: list[str] = []
	for sequence_id, expected_count in EXPECTED_SEQUENCES.items():
		json_path = sequence_json(sequence_id)
		if not json_path.exists():
			errors.append(f"missing sequence json: {json_path.relative_to(ROOT)}")
			continue
		frames = frame_paths(sequence_id)
		if len(frames) != expected_count:
			errors.append(f"{sequence_id} has {len(frames)} referenced frames, expected {expected_count}")
		for frame in frames:
			if not frame.exists():
				errors.append(f"missing sequence frame: {frame.relative_to(ROOT)}")
				continue
			metrics = image_alpha_metrics(frame)
			if metrics["edge_max"] > 8.0:
				errors.append(f"{frame.relative_to(ROOT)} alpha touches canvas edge: {metrics['edge_max']:.1f}")
			if sequence_id in {"vfx_hit_fire", "vfx_explosion_fire", "vfx_active_sig_blaze_meltdown"}:
				if abs(metrics["centroid_x"] - 0.5) > 0.2:
					errors.append(f"{frame.relative_to(ROOT)} fire centroid is too directional: {metrics['centroid_x']:.2f}")
				if metrics["bbox_w"] > 0.94 and metrics["bbox_h"] > 0.94:
					errors.append(f"{frame.relative_to(ROOT)} alpha bbox nearly fills canvas; possible rectangular cutout")

	for name, (min_duration, max_duration) in ACTIVE_SFX.items():
		path = AUDIO_DIR / name
		if not path.exists():
			errors.append(f"missing active skill sfx: {path.relative_to(ROOT)}")
			continue
		metrics = wav_metrics(path)
		if metrics["sample_rate"] != 44100:
			errors.append(f"{name} sample rate must be 44100 Hz")
		if not (min_duration <= metrics["duration"] <= max_duration):
			errors.append(f"{name} duration {metrics['duration']:.2f}s outside {min_duration:.1f}-{max_duration:.1f}s")
		if metrics["peak_db"] > -3.0:
			errors.append(f"{name} peak too hot: {metrics['peak_db']:.2f} dBFS")
		if not (-24.5 <= metrics["rms_db"] <= -10.0):
			errors.append(f"{name} rms outside mix target: {metrics['rms_db']:.2f} dBFS")

	if errors:
		for error in errors:
			print(f"active skill media check failed: {error}", file=sys.stderr)
		return 1
	print("Active skill media OK: fire VFX centered, alpha edges clean, active SFX bounded")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
