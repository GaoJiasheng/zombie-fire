#!/usr/bin/env python3
"""Build Golden Law premium VFX sequences and restrained one-shot SFX."""

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
SOURCE = ROOT / "assets/production/source_refs/generated/premium_black_gold_golden_law_phase4_2026_08_01"
DECREE_GATHER_MASTER = SOURCE / "golden_decree_gather_transparent_v3.png"
DECREE_IMPACT_MASTER = SOURCE / "golden_decree_impact_transparent_v3.png"
RENDERED_MASTERS = {
    "vfx_status_golden_law_judgment": SOURCE / "golden_judgment_status_transparent_v1.png",
    "vfx_apocalypse_golden_law_falcon": SOURCE / "golden_skyfalcon_dive_transparent_v1.png",
    "vfx_apocalypse_golden_law_counter": SOURCE / "golden_eternal_counter_transparent_v1.png",
    "vfx_apocalypse_golden_law_awakening": SOURCE / "golden_sovereign_awakening_transparent_v1.png",
}
SEQUENCE_ROOT = ROOT / "assets/production/sprites/vfx_sequences"
AUDIO_ROOT = ROOT / "assets/production/audio/sfx"
CONTACT = SOURCE / "golden_law_vfx_runtime_contact_sheet.png"
MANIFEST = SOURCE / "golden_law_vfx_runtime_manifest.json"

CELLS = {
    "vfx_status_golden_law_judgment": (0, 0),
    "vfx_apocalypse_golden_law_impact": (1, 0),
    "vfx_apocalypse_golden_law_decree": (2, 0),
    "vfx_apocalypse_golden_law_falcon": (0, 1),
    "vfx_apocalypse_golden_law_counter": (1, 1),
    "vfx_apocalypse_golden_law_awakening": (2, 1),
}
FRAME_SPECS = {
    "vfx_status_golden_law_judgment": [(0.97, .72, -.3), (.985, .84, -.1), (1., .94, .1), (1.012, .88, .3), (.995, .80, .08), (.978, .74, -.18)],
    "vfx_apocalypse_golden_law_impact": [(.44, .28, -1.2), (.60, .54, -.8), (.78, .78, -.35), (.96, 1., 0.), (1.05, .88, .4), (1.10, .64, .8), (1.14, .38, 1.2), (1.17, .14, 1.5)],
    "vfx_apocalypse_golden_law_decree": [(.58, .26, -.5), (.70, .50, -.3), (.84, .76, -.1), (.98, 1., 0.), (1.04, .82, .15), (1.09, .52, .3), (1.13, .18, .45)],
    "vfx_apocalypse_golden_law_falcon": [(.70, .25, -.8), (.80, .48, -.5), (.90, .72, -.2), (1., 1., 0.), (1.04, .90, .2), (1.07, .68, .4), (1.10, .42, .6), (1.12, .15, .8)],
    "vfx_apocalypse_golden_law_counter": [(.52, .22, 0.), (.66, .46, 0.), (.80, .72, 0.), (.96, 1., 0.), (1.04, .90, 0.), (1.09, .64, 0.), (1.13, .36, 0.), (1.16, .12, 0.)],
    "vfx_apocalypse_golden_law_awakening": [(.58, .24, 0.), (.70, .44, 0.), (.82, .66, 0.), (.93, .86, 0.), (1., 1., 0.), (1.04, .88, 0.), (1.07, .60, 0.), (1.10, .20, 0.)],
}
FPS = {
    "vfx_status_golden_law_judgment": 12,
    "vfx_apocalypse_golden_law_impact": 18,
    "vfx_apocalypse_golden_law_decree": 16,
    "vfx_apocalypse_golden_law_falcon": 16,
    "vfx_apocalypse_golden_law_counter": 17,
    "vfx_apocalypse_golden_law_awakening": 15,
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


def gold_grade(image: Image.Image) -> Image.Image:
    """Remove chroma reflections without flattening white-hot gold highlights."""
    rgba = np.asarray(image.convert("RGBA"), dtype=np.float32).copy()
    red, green, blue, alpha = [rgba[:, :, index] for index in range(4)]
    spill = (alpha > 2.) & (green > red * .90 + 10.) & (green > blue * 1.30)
    corrected_red = np.maximum(red, green * .94)
    red[spill] = corrected_red[spill]
    green[spill] = np.minimum(green[spill], corrected_red[spill] * .79 + 12.)
    blue[spill] = np.minimum(blue[spill], green[spill] * .34 + 5.)
    return Image.fromarray(rgba.clip(0, 255).astype(np.uint8))


def rendered_asset_frame(
    master: Image.Image,
    scale: float,
    alpha: float,
    offset_y: int = 0,
    brightness: float = 1.0,
    fill: float = .74,
) -> Image.Image:
    """Animate a deeply rendered source while retaining a real atlas guard band."""
    base = fit_alpha(gold_grade(master), (512, 512), fill)
    side = max(1, round(512 * scale))
    layer = base.resize((side, side), Image.Resampling.LANCZOS)
    layer = ImageEnhance.Brightness(layer).enhance(brightness)
    layer.putalpha(layer.getchannel("A").point(lambda value: round(value * alpha)))
    canvas = Image.new("RGBA", (512, 512))
    canvas.alpha_composite(layer, ((512 - side) // 2, (512 - side) // 2 + offset_y))
    return canvas


def rendered_golden_frame(
    sequence_id: str,
    index: int,
    gather_master: Image.Image,
    impact_master: Image.Image,
) -> Image.Image:
    if sequence_id == "vfx_apocalypse_golden_law_impact":
        phases = [
            (.48, .20, -18, .92),
            (.62, .44, -12, .98),
            (.78, .72, -6, 1.04),
            (.94, 1.00, 0, 1.10),
            (1.00, .82, 2, 1.04),
            (1.03, .58, 4, .98),
            (1.05, .32, 5, .92),
            (1.06, .12, 6, .88),
        ]
        scale, opacity, offset_y, brightness = phases[index]
        return rendered_asset_frame(impact_master, scale, opacity, offset_y, brightness)
    # Golden Decree has a readable three-beat arc: seal gathers, verdict lands,
    # then the molten pressure wave releases. It is intentionally not a loop of
    # rotating geometry.
    gather_phases = [
        (.66, .24, -18, .90),
        (.78, .48, -12, .98),
        (.90, .78, -6, 1.04),
        (.98, 1.00, 0, 1.10),
    ]
    impact_phases = [
        (.82, .46, -2, 1.04),
        (.96, .92, 2, 1.10),
        (1.02, .54, 4, 1.00),
        (1.04, .18, 5, .90),
    ]
    if index < 3:
        scale, opacity, offset_y, brightness = gather_phases[index]
        return rendered_asset_frame(gather_master, scale, opacity, offset_y, brightness)
    if index == 3:
        gather = rendered_asset_frame(gather_master, *gather_phases[index])
        impact = rendered_asset_frame(impact_master, *impact_phases[0])
        return Image.alpha_composite(gather, impact)
    scale, opacity, offset_y, brightness = impact_phases[index - 3]
    return rendered_asset_frame(impact_master, scale, opacity, offset_y, brightness)


def rendered_special_frame(sequence_id: str, index: int, master: Image.Image) -> Image.Image:
    """Animate the four former line-art placeholders from authored raster masters."""
    phases = {
        "vfx_status_golden_law_judgment": [
            (.70, .26, 4, .88), (.79, .52, 2, .96), (.88, .86, 0, 1.04),
            (.92, 1.00, -2, 1.08), (.89, .72, 0, 1.00), (.84, .30, 2, .92),
        ],
        # The falcon moves from top to bottom. The authored beak is the lower
        # leading point, so only translation/scale is used; no ambiguous spin.
        "vfx_apocalypse_golden_law_falcon": [
            (.58, .16, -58, .90), (.66, .34, -42, .96), (.75, .58, -24, 1.02),
            (.86, .88, -8, 1.08), (.94, 1.00, 8, 1.10), (.98, .76, 24, 1.04),
            (1.01, .44, 38, .98), (1.03, .16, 38, .90),
        ],
        # The lower aegis releases upward; its movement reinforces the source
        # silhouette instead of rotating it into a contradictory direction.
        "vfx_apocalypse_golden_law_counter": [
            (.62, .18, 34, .90), (.70, .38, 28, .96), (.78, .64, 20, 1.02),
            (.88, .92, 10, 1.08), (.96, 1.00, 0, 1.10), (.99, .72, -12, 1.04),
            (1.01, .40, -22, .96), (1.02, .14, -30, .88),
        ],
        "vfx_apocalypse_golden_law_awakening": [
            (.70, .16, 22, .88), (.77, .32, 16, .94), (.84, .54, 10, 1.00),
            (.91, .78, 4, 1.06), (.96, 1.00, 0, 1.10), (.99, .82, -2, 1.06),
            (1.01, .50, -4, .98), (1.02, .16, -5, .90),
        ],
    }[sequence_id]
    scale, opacity, offset_y, brightness = phases[index]
    # The four independent masters include long silk/glow tails.  Keep a wider
    # atlas guard band than compact impact effects so translated anticipation
    # and recovery frames cannot clip on bright alpha fringes.
    return rendered_asset_frame(master, scale, opacity, offset_y, brightness, .68)


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
    entries: list[dict] = []
    peaks: list[tuple[str, Image.Image]] = []
    required_masters = [DECREE_GATHER_MASTER, DECREE_IMPACT_MASTER, *RENDERED_MASTERS.values()]
    missing_masters = [path for path in required_masters if not path.exists()]
    if missing_masters:
        raise FileNotFoundError(f"deep-rendered Golden Law source masters are missing: {missing_masters}")
    gather_master = Image.open(DECREE_GATHER_MASTER).convert("RGBA")
    impact_master = Image.open(DECREE_IMPACT_MASTER).convert("RGBA")
    rendered_masters = {
        sequence_id: Image.open(path).convert("RGBA")
        for sequence_id, path in RENDERED_MASTERS.items()
    }
    for sequence_id in CELLS:
        out = SEQUENCE_ROOT / sequence_id
        out.mkdir(parents=True, exist_ok=True)
        specs = FRAME_SPECS[sequence_id]
        frames: list[str] = []
        for index, spec in enumerate(specs, 1):
            if sequence_id in {
                "vfx_apocalypse_golden_law_decree",
                "vfx_apocalypse_golden_law_impact",
            }:
                frame = rendered_golden_frame(
                    sequence_id,
                    index - 1,
                    gather_master,
                    impact_master,
                )
            elif sequence_id in rendered_masters:
                frame = rendered_special_frame(sequence_id, index - 1, rendered_masters[sequence_id])
            else:
                raise RuntimeError(f"missing rendered Golden Law route: {sequence_id}")
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
            "source": (
                [str(DECREE_GATHER_MASTER.relative_to(ROOT)), str(DECREE_IMPACT_MASTER.relative_to(ROOT))]
                if sequence_id in {"vfx_apocalypse_golden_law_decree", "vfx_apocalypse_golden_law_impact"}
                else str(RENDERED_MASTERS[sequence_id].relative_to(ROOT))
            ),
            "integration": "Gilded Eclipse / Golden Law semantic VFX; alpha bitmap sequence; no recursion",
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
        "sfx_apocalypse_golden_law_fire.wav": ("fire", .20, 307),
        "sfx_apocalypse_golden_law_impact.wav": ("shatter", .64, 619),
        "sfx_apocalypse_golden_law_decree.wav": ("field", .82, 977),
        "sfx_apocalypse_golden_law_falcon.wav": ("field", .70, 1117),
        "sfx_apocalypse_golden_law_counter.wav": ("counter", .72, 1301),
        "sfx_apocalypse_golden_law_awakening.wav": ("awakening", 1.18, 1699),
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
    print(f"Golden Law VFX runtime built: {len(entries)} tracked outputs")


if __name__ == "__main__":
    main()
