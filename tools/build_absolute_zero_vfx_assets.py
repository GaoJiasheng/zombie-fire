#!/usr/bin/env python3
"""Build Absolute Zero premium VFX sequences and restrained one-shot SFX."""

from __future__ import annotations

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/production/source_refs/generated/premium_polar_aurora_absolute_zero_phase3_2026_08_01"
MASTER_CHROMA = SOURCE / "absolute_zero_vfx_master_chroma.png"
MASTER = SOURCE / "absolute_zero_vfx_master.png"
SEQUENCE_ROOT = ROOT / "assets/production/sprites/vfx_sequences"
AUDIO_ROOT = ROOT / "assets/production/audio/sfx"
CONTACT = SOURCE / "absolute_zero_vfx_runtime_contact_sheet.png"
MANIFEST = SOURCE / "absolute_zero_vfx_runtime_manifest.json"

CELLS = {
    "vfx_status_absolute_zero_brittle": (0, 0),
    "vfx_apocalypse_absolute_zero_shatter": (1, 0),
    "vfx_apocalypse_absolute_zero_wave": (2, 0),
    "vfx_apocalypse_absolute_zero_field": (0, 1),
    "vfx_apocalypse_absolute_zero_counter": (1, 1),
    "vfx_apocalypse_absolute_zero_awakening": (2, 1),
}
FRAME_SPECS = {
    "vfx_status_absolute_zero_brittle": [(0.97, .72, -.3), (.985, .84, -.1), (1., .94, .1), (1.012, .88, .3), (.995, .80, .08), (.978, .74, -.18)],
    "vfx_apocalypse_absolute_zero_shatter": [(.44, .28, -1.2), (.60, .54, -.8), (.78, .78, -.35), (.96, 1., 0.), (1.05, .88, .4), (1.10, .64, .8), (1.14, .38, 1.2), (1.17, .14, 1.5)],
    "vfx_apocalypse_absolute_zero_wave": [(.58, .26, -.5), (.70, .50, -.3), (.84, .76, -.1), (.98, 1., 0.), (1.04, .82, .15), (1.09, .52, .3), (1.13, .18, .45)],
    "vfx_apocalypse_absolute_zero_field": [(.70, .25, -.8), (.80, .48, -.5), (.90, .72, -.2), (1., 1., 0.), (1.04, .90, .2), (1.07, .68, .4), (1.10, .42, .6), (1.12, .15, .8)],
    "vfx_apocalypse_absolute_zero_counter": [(.52, .22, 0.), (.66, .46, 0.), (.80, .72, 0.), (.96, 1., 0.), (1.04, .90, 0.), (1.09, .64, 0.), (1.13, .36, 0.), (1.16, .12, 0.)],
    "vfx_apocalypse_absolute_zero_awakening": [(.58, .24, 0.), (.70, .44, 0.), (.82, .66, 0.), (.93, .86, 0.), (1., 1., 0.), (1.04, .88, 0.), (1.07, .60, 0.), (1.10, .20, 0.)],
}
FPS = {
    "vfx_status_absolute_zero_brittle": 12,
    "vfx_apocalypse_absolute_zero_shatter": 18,
    "vfx_apocalypse_absolute_zero_wave": 16,
    "vfx_apocalypse_absolute_zero_field": 16,
    "vfx_apocalypse_absolute_zero_counter": 17,
    "vfx_apocalypse_absolute_zero_awakening": 15,
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def remove_green(image: Image.Image) -> Image.Image:
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    red, green, blue = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    strongest = np.maximum(red, blue)
    excess = green - strongest
    candidate = (green > 86.) & (green > red * 1.25) & (green > blue * 1.14)
    alpha = np.where(candidate, 255. - np.clip((excess - 20.) / 94., 0., 1.) * 255., 255.)
    alpha = np.where((green > 178.) & (excess > 102.), 0., alpha)
    partial = (alpha > 0.) & (alpha < 255.)
    green[partial] = np.minimum(green[partial], strongest[partial] * 1.02)
    rgba = np.dstack((red, green, blue, alpha)).clip(0, 255).astype(np.uint8)
    # Remove tiny keyed flecks while preserving deliberately separated shards.
    mask = (rgba[:, :, 3] > 18).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
    for label in range(1, count):
        if int(stats[label, cv2.CC_STAT_AREA]) < 18:
            rgba[labels == label, 3] = 0
    return Image.fromarray(rgba)


def fit_alpha(image: Image.Image, size: tuple[int, int], fill: float) -> Image.Image:
    image = image.convert("RGBA")
    box = image.getbbox()
    if box is None:
        raise RuntimeError("empty keyed VFX cell")
    image = image.crop(box)
    scale = min(size[0] * fill / image.width, size[1] * fill / image.height)
    image = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size)
    canvas.alpha_composite(image, ((size[0] - image.width) // 2, (size[1] - image.height) // 2))
    return canvas


def animated_frame(master: Image.Image, scale: float, alpha: float, angle: float) -> Image.Image:
    base = fit_alpha(master, (512, 512), .70)
    layer = base.rotate(angle, resample=Image.Resampling.BICUBIC, expand=False)
    if scale != 1.0:
        resized = layer.resize((max(1, round(512 * scale)), max(1, round(512 * scale))), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (512, 512))
        canvas.alpha_composite(resized, ((512 - resized.width) // 2, (512 - resized.height) // 2))
        layer = canvas
    layer = ImageEnhance.Brightness(layer).enhance(.84 + .20 * alpha)
    layer.putalpha(layer.getchannel("A").point(lambda value: round(value * alpha)))
    return layer


def build_sequences() -> list[dict]:
    cleaned = remove_green(Image.open(MASTER_CHROMA))
    cleaned.save(MASTER, optimize=True)
    entries: list[dict] = []
    peaks: list[tuple[str, Image.Image]] = []
    for sequence_id, (col, row) in CELLS.items():
        x0, x1 = round(cleaned.width * col / 3), round(cleaned.width * (col + 1) / 3)
        y0, y1 = round(cleaned.height * row / 2), round(cleaned.height * (row + 1) / 2)
        cell = cleaned.crop((x0 + 6, y0 + 6, x1 - 6, y1 - 6))
        out = SEQUENCE_ROOT / sequence_id
        out.mkdir(parents=True, exist_ok=True)
        specs = FRAME_SPECS[sequence_id]
        frames: list[str] = []
        for index, spec in enumerate(specs, 1):
            frame = animated_frame(cell, *spec)
            path = out / f"{sequence_id}_{index:02d}.png"
            frame.save(path, optimize=True)
            frames.append(str(path.relative_to(ROOT / "assets/production")))
            entries.append({"path": str(path.relative_to(ROOT)), "kind": "vfx_frame", "sha256": sha256(path)})
        peak = max(range(len(specs)), key=lambda idx: specs[idx][1]) + 1
        peaks.append((sequence_id, Image.open(out / f"{sequence_id}_{peak:02d}.png").convert("RGBA")))
        sequence_path = out / f"{sequence_id}_sequence.json"
        sequence_path.write_text(json.dumps({
            "id": sequence_id,
            "fps": FPS[sequence_id],
            "frames": frames,
            "source": str(MASTER.relative_to(ROOT)),
            "integration": "Polar Aurora / Absolute Zero semantic VFX; alpha bitmap sequence; no recursion",
        }, ensure_ascii=False, indent=2) + "\n")
        entries.append({"path": str(sequence_path.relative_to(ROOT)), "kind": "vfx_sequence", "sha256": sha256(sequence_path)})
    contact = Image.new("RGB", (1536, 1024), (5, 11, 22))
    draw = ImageDraw.Draw(contact)
    for index, (sequence_id, image) in enumerate(peaks):
        x, y = (index % 3) * 512, (index // 3) * 512
        thumb = fit_alpha(image, (480, 430), .94)
        contact.paste(thumb, (x + 16, y + 18), thumb)
        draw.text((x + 22, y + 462), sequence_id, fill=(210, 238, 255))
    contact.save(CONTACT, quality=94)
    entries.append({"path": str(CONTACT.relative_to(ROOT)), "kind": "verification_contact_sheet", "sha256": sha256(CONTACT)})
    return entries


def envelope(t: float, duration: float, attack: float, release: float) -> float:
    return min(1., t / max(attack, 1e-5)) * min(1., (duration - t) / max(release, 1e-5))


def synth(kind: str, duration: float, seed: int) -> list[float]:
    rate = 44100
    rng = random.Random(seed)
    values: list[float] = []
    noise_state = 0.
    for index in range(round(duration * rate)):
        t = index / rate
        p = t / duration
        noise_state = noise_state * .86 + rng.uniform(-1., 1.) * .14
        env = envelope(t, duration, .008 if kind == "fire" else .02, .10 if kind == "fire" else .24)
        if kind == "fire":
            freq = 620. - 240. * p
            value = math.sin(2 * math.pi * freq * t) * .40 + noise_state * .30
        elif kind == "shatter":
            crack = rng.uniform(-1., 1.) if rng.random() < .045 * (1. - p) else 0.
            value = math.sin(2 * math.pi * (180. - 90. * p) * t) * .42 + noise_state * .22 + crack * .70
        elif kind == "field":
            freq = 150. + 340. * p
            value = math.sin(2 * math.pi * freq * t) * .28 + noise_state * .34
        elif kind == "counter":
            value = math.sin(2 * math.pi * (74. + 54. * p) * t) * .58 + noise_state * .28
        else:
            root = 118. + 42. * p
            value = (math.sin(2 * math.pi * root * t) + .55 * math.sin(2 * math.pi * root * 1.5 * t)) * .31 + noise_state * .16
        values.append(value * env)
    peak = max(max(abs(value) for value in values), 1e-6)
    return [max(-1., min(1., value * .88 / peak)) for value in values]


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(44100)
        output.writeframes(b"".join(struct.pack("<h", round(value * 32767.)) for value in samples))


def build_audio() -> list[dict]:
    specs = {
        "sfx_apocalypse_absolute_zero_fire.wav": ("fire", .20, 307),
        "sfx_apocalypse_absolute_zero_shatter.wav": ("shatter", .64, 619),
        "sfx_apocalypse_absolute_zero_field.wav": ("field", .82, 977),
        "sfx_apocalypse_absolute_zero_counter.wav": ("counter", .72, 1301),
        "sfx_apocalypse_absolute_zero_awakening.wav": ("awakening", 1.18, 1699),
    }
    entries: list[dict] = []
    for filename, (kind, duration, seed) in specs.items():
        path = AUDIO_ROOT / filename
        write_wav(path, synth(kind, duration, seed))
        entries.append({"path": str(path.relative_to(ROOT)), "kind": "sfx", "sha256": sha256(path)})
    return entries


def main() -> None:
    entries = build_sequences() + build_audio()
    MANIFEST.write_text(json.dumps({"version": 1, "count": len(entries), "assets": entries}, ensure_ascii=False, indent=2) + "\n")
    print(f"Absolute Zero VFX runtime built: {len(entries)} tracked outputs")


if __name__ == "__main__":
    main()
