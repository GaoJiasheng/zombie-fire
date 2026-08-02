#!/usr/bin/env python3
"""Build the approved Inferno Apocalypse Step-4 VFX and audio package.

The raster master is generated once through imagegen on chroma green and then
cleaned to alpha.  This script only performs deterministic production work:
cell extraction, phone-readable animation timing, contact-sheet verification,
sequence metadata, and short layered one-shot SFX.  It never changes combat
values or StoreKit state.
"""

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
SOURCE = ROOT / "assets/production/source_refs/generated/premium_infernal_dominion_inferno_phase2_2026_07_31"
MASTER = SOURCE / "inferno_apocalypse_step4_vfx_master.png"
SEQUENCE_ROOT = ROOT / "assets/production/sprites/vfx_sequences"
AUDIO_ROOT = ROOT / "assets/production/audio/sfx"
CONTACT = SOURCE / "inferno_apocalypse_step4_runtime_contact_sheet.png"
MANIFEST = SOURCE / "inferno_apocalypse_step4_runtime_manifest.json"


# The imagegen master is 1535x1024: three intentionally isolated columns and
# two rows.  Half-open bounds keep every source pixel while avoiding overlap.
CELLS = {
    "vfx_status_inferno_burn": (0, 0, 512, 512),
    "vfx_apocalypse_inferno_combustion": (512, 0, 1024, 512),
    "vfx_apocalypse_inferno_spread": (1024, 0, 1535, 512),
    "vfx_apocalypse_inferno_phoenix": (0, 512, 512, 1024),
    "vfx_apocalypse_inferno_counter": (512, 512, 1024, 1024),
    "vfx_apocalypse_inferno_awakening": (1024, 512, 1535, 1024),
}

FRAME_SPECS = {
    # Continuous status: a closed breathing loop; no floating ground circle.
    "vfx_status_inferno_burn": [
        (0.955, 0.76, -0.45), (0.982, 0.88, -0.12), (1.000, 1.00, 0.20),
        (1.018, 0.92, 0.42), (0.995, 0.84, 0.10), (0.968, 0.78, -0.25),
    ],
    # Transient effects grow into their authored silhouette and then release.
    "vfx_apocalypse_inferno_combustion": [
        (0.45, 0.34, -2.4), (0.62, 0.62, -1.5), (0.82, 0.86, -0.7),
        (1.00, 1.00, 0.0), (1.07, 0.92, 0.8), (1.12, 0.72, 1.7),
        (1.15, 0.46, 2.5), (1.18, 0.18, 3.1),
    ],
    "vfx_apocalypse_inferno_spread": [
        (0.58, 0.30, -1.0), (0.70, 0.54, -0.7), (0.83, 0.78, -0.35),
        (0.96, 1.00, 0.0), (1.03, 0.82, 0.28), (1.08, 0.55, 0.55),
        (1.12, 0.22, 0.8),
    ],
    "vfx_apocalypse_inferno_phoenix": [
        (0.72, 0.30, -1.0), (0.82, 0.58, -0.6), (0.91, 0.82, -0.25),
        (1.00, 1.00, 0.0), (1.04, 0.94, 0.25), (1.07, 0.74, 0.45),
        (1.10, 0.48, 0.65), (1.12, 0.18, 0.8),
    ],
    "vfx_apocalypse_inferno_counter": [
        (0.54, 0.26, 0.0), (0.68, 0.52, 0.0), (0.82, 0.78, 0.0),
        (0.96, 1.00, 0.0), (1.04, 0.91, 0.0), (1.09, 0.68, 0.0),
        (1.13, 0.40, 0.0), (1.16, 0.16, 0.0),
    ],
    "vfx_apocalypse_inferno_awakening": [
        (0.60, 0.28, 0.0), (0.72, 0.48, 0.0), (0.84, 0.70, 0.0),
        (0.94, 0.88, 0.0), (1.00, 1.00, 0.0), (1.04, 0.92, 0.0),
        (1.07, 0.68, 0.0), (1.10, 0.32, 0.0),
    ],
}

FPS = {
    "vfx_status_inferno_burn": 12,
    "vfx_apocalypse_inferno_combustion": 18,
    "vfx_apocalypse_inferno_spread": 16,
    "vfx_apocalypse_inferno_phoenix": 18,
    "vfx_apocalypse_inferno_counter": 17,
    "vfx_apocalypse_inferno_awakening": 15,
}


def fit_alpha(image: Image.Image, size: tuple[int, int], fill: float) -> Image.Image:
    image = image.convert("RGBA")
    box = image.getbbox()
    if box is None:
        raise RuntimeError("empty alpha VFX cell")
    image = image.crop(box)
    scale = min(size[0] * fill / image.width, size[1] * fill / image.height)
    image = image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", size)
    canvas.alpha_composite(image, ((size[0] - image.width) // 2, (size[1] - image.height) // 2))
    return canvas


def keep_largest_alpha_component(image: Image.Image) -> Image.Image:
    """Remove a neighboring-cell spark without clipping the authored effect."""
    rgba = np.asarray(image.convert("RGBA")).copy()
    mask = (rgba[:, :, 3] > 18).astype(np.uint8)
    count, labels, stats, _centroids = cv2.connectedComponentsWithStats(mask, 8)
    if count <= 1:
        return image.convert("RGBA")
    largest = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    rgba[labels != largest, 3] = 0
    return Image.fromarray(rgba)


def remove_green_spill(image: Image.Image) -> Image.Image:
    """Neutralize residual chroma fringe while preserving white-hot cores."""
    rgba = np.asarray(image.convert("RGBA")).copy()
    rgb = rgba[:, :, :3].astype(np.float32)
    alpha = rgba[:, :, 3].astype(np.float32)
    red, green, blue = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    true_white_hot = (red > 205.0) & (green > 168.0) & (blue > 82.0)
    spill = (~true_white_hot) & (alpha > 0.0) & (green > red * 0.86 + 12.0) & (green > blue * 1.12)
    severe = spill & (green > red * 1.20 + 18.0)
    rgb[:, :, 1] = np.where(spill, np.minimum(green, red * 0.62 + blue * 0.12 + 8.0), green)
    rgb[:, :, 2] = np.where(spill, np.minimum(blue, red * 0.28 + 8.0), blue)
    alpha = np.where(severe, alpha * 0.36, alpha)
    rgba[:, :, :3] = np.clip(rgb, 0.0, 255.0).astype(np.uint8)
    rgba[:, :, 3] = np.clip(alpha, 0.0, 255.0).astype(np.uint8)
    return Image.fromarray(rgba)


def animated_frame(master: Image.Image, scale: float, alpha: float, angle: float) -> Image.Image:
    # Reserve the same 7.5% alpha-safe margin enforced for every production
    # sequence even on the largest release frame. Runtime scale supplies the
    # spectacle; source pixels themselves must never be pre-cropped.
    base = fit_alpha(master, (512, 512), 0.70)
    layer = base.rotate(angle, resample=Image.Resampling.BICUBIC, expand=False)
    if scale != 1.0:
        resized = layer.resize(
            (max(1, round(512 * scale)), max(1, round(512 * scale))),
            Image.Resampling.LANCZOS,
        )
        canvas = Image.new("RGBA", (512, 512))
        canvas.alpha_composite(resized, ((512 - resized.width) // 2, (512 - resized.height) // 2))
        layer = canvas
    # Brightness grows with the authored alpha beat so the white-hot core peaks
    # at contact without resorting to a full-screen flash.
    layer = remove_green_spill(ImageEnhance.Brightness(layer).enhance(0.84 + 0.22 * alpha))
    layer.putalpha(layer.getchannel("A").point(lambda p: round(p * alpha)))
    return layer


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build_sequences() -> list[dict]:
    source = Image.open(MASTER).convert("RGBA")
    entries: list[dict] = []
    peaks: list[tuple[str, Image.Image]] = []
    for sequence_id, bounds in CELLS.items():
        cell = source.crop(bounds)
        if sequence_id in ["vfx_status_inferno_burn", "vfx_apocalypse_inferno_spread"]:
            cell = keep_largest_alpha_component(cell)
        out_dir = SEQUENCE_ROOT / sequence_id
        out_dir.mkdir(parents=True, exist_ok=True)
        frame_paths: list[str] = []
        specs = FRAME_SPECS[sequence_id]
        for index, spec in enumerate(specs, 1):
            frame = animated_frame(cell, *spec)
            path = out_dir / f"{sequence_id}_{index:02d}.png"
            frame.save(path, optimize=True)
            frame_paths.append(str(path.relative_to(ROOT / "assets/production")))
            entries.append({"path": str(path.relative_to(ROOT)), "kind": "vfx_frame", "sha256": sha256(path)})
        peak_index = max(range(len(specs)), key=lambda i: specs[i][1])
        peaks.append((sequence_id, Image.open(out_dir / f"{sequence_id}_{peak_index + 1:02d}.png").convert("RGBA")))
        metadata = {
            "id": sequence_id,
            "fps": FPS[sequence_id],
            "frames": frame_paths,
            "source": "assets/production/source_refs/generated/premium_infernal_dominion_inferno_phase2_2026_07_31/inferno_apocalypse_step4_vfx_master.png",
            "integration": "owner-approved Step-4 Inferno semantic VFX; alpha bitmap sequence; no SVG/vector",
        }
        sequence_path = out_dir / f"{sequence_id}_sequence.json"
        sequence_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")
        entries.append({"path": str(sequence_path.relative_to(ROOT)), "kind": "vfx_sequence", "sha256": sha256(sequence_path)})
    build_contact_sheet(peaks)
    entries.append({"path": str(CONTACT.relative_to(ROOT)), "kind": "verification_contact_sheet", "sha256": sha256(CONTACT)})
    return entries


def build_contact_sheet(peaks: list[tuple[str, Image.Image]]) -> None:
    sheet = Image.new("RGB", (1536, 1024), (7, 9, 12))
    draw = ImageDraw.Draw(sheet)
    for index, (sequence_id, image) in enumerate(peaks):
        x = (index % 3) * 512
        y = (index // 3) * 512
        thumb = fit_alpha(image, (480, 430), 0.94)
        sheet.paste(thumb, (x + 16, y + 18), thumb)
        draw.text((x + 22, y + 462), sequence_id, fill=(242, 211, 174))
    sheet.save(CONTACT, quality=94)


def envelope(t: float, duration: float, attack: float, release: float) -> float:
    return min(1.0, t / max(attack, 1e-5)) * min(1.0, (duration - t) / max(release, 1e-5))


def synth_sfx(kind: str, duration: float, seed: int) -> list[float]:
    sample_rate = 44100
    rng = random.Random(seed)
    count = round(duration * sample_rate)
    values: list[float] = []
    filtered_noise = 0.0
    for i in range(count):
        t = i / sample_rate
        p = t / duration
        noise = rng.uniform(-1.0, 1.0)
        filtered_noise = filtered_noise * 0.78 + noise * 0.22
        env = envelope(t, duration, 0.008 if kind == "ignition" else 0.025, 0.10 if kind == "ignition" else 0.24)
        if kind == "ignition":
            freq = 240.0 - 105.0 * p
            value = math.sin(2.0 * math.pi * freq * t) * 0.42 + filtered_noise * (0.46 * (1.0 - p))
        elif kind == "combustion":
            freq = 92.0 - 48.0 * p
            crackle = noise * (1.0 if rng.random() < 0.035 * (1.0 - p) else 0.0)
            value = math.sin(2.0 * math.pi * freq * t) * 0.64 + filtered_noise * 0.30 + crackle * 0.58
        elif kind == "phoenix":
            sweep = 160.0 + 560.0 * (p ** 1.45)
            value = math.sin(2.0 * math.pi * sweep * t) * 0.24 + filtered_noise * (0.60 * math.sin(math.pi * p))
        elif kind == "counter":
            freq = 66.0 + 38.0 * p
            value = math.sin(2.0 * math.pi * freq * t) * 0.58 + filtered_noise * (0.44 * (1.0 - 0.35 * p))
        else:  # awakening
            root = 92.0 + 46.0 * p
            chord = (
                math.sin(2.0 * math.pi * root * t)
                + 0.62 * math.sin(2.0 * math.pi * root * 1.5 * t)
                + 0.38 * math.sin(2.0 * math.pi * root * 2.0 * t)
            )
            value = chord * 0.31 + filtered_noise * (0.18 * (1.0 - p))
        values.append(value * env)
    peak = max(max(abs(value) for value in values), 1e-6)
    return [max(-1.0, min(1.0, value * 0.88 / peak)) for value in values]


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(44100)
        output.writeframes(b"".join(struct.pack("<h", round(value * 32767.0)) for value in samples))


def build_audio() -> list[dict]:
    specs = {
        "sfx_apocalypse_inferno_ignition.wav": ("ignition", 0.18, 411),
        "sfx_apocalypse_inferno_combustion.wav": ("combustion", 0.62, 823),
        "sfx_apocalypse_inferno_phoenix.wav": ("phoenix", 0.84, 1237),
        "sfx_apocalypse_inferno_counter.wav": ("counter", 0.70, 1663),
        "sfx_apocalypse_inferno_awakening.wav": ("awakening", 1.18, 2081),
    }
    entries: list[dict] = []
    for filename, (kind, duration, seed) in specs.items():
        path = AUDIO_ROOT / filename
        write_wav(path, synth_sfx(kind, duration, seed))
        entries.append({"path": str(path.relative_to(ROOT)), "kind": "sfx", "sha256": sha256(path)})
    return entries


def main() -> None:
    if not MASTER.exists():
        raise SystemExit(f"Missing cleaned Step-4 VFX master: {MASTER}")
    entries = build_sequences() + build_audio()
    MANIFEST.write_text(json.dumps({"version": 1, "count": len(entries), "assets": entries}, ensure_ascii=False, indent=2) + "\n")
    print(f"Inferno Step-4 runtime built: {len(entries)} tracked outputs")


if __name__ == "__main__":
    main()
