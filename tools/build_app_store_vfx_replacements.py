#!/usr/bin/env python3
"""Replace the final two generic procedural-looking VFX with rendered masters."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/production/source_refs/generated/app_store_placeholder_audit_2026_08_01"
SEQUENCE_ROOT = ROOT / "assets/production/sprites/vfx_sequences"
SINGLE_ROOT = ROOT / "assets/production/sprites/vfx"
CONTACT = SOURCE / "app_store_vfx_replacements_contact_sheet.png"
MANIFEST = SOURCE / "app_store_vfx_replacements_manifest.json"

MASTERS = {
    "vfx_enemy_skill_enrage": SOURCE / "enemy_enrage_transparent_v1.png",
    "vfx_levelup_glow": SOURCE / "levelup_ascension_transparent_v1.png",
}
FPS = {"vfx_enemy_skill_enrage": 20, "vfx_levelup_glow": 20}
PHASES = {
    "vfx_enemy_skill_enrage": [
        (.58, .12, 12, .84), (.64, .24, 9, .90), (.71, .40, 6, .96),
        (.79, .62, 3, 1.02), (.87, .84, 0, 1.07), (.94, 1.00, -2, 1.10),
        (.98, .92, -3, 1.08), (1.00, .78, -2, 1.04), (1.01, .60, 0, 1.00),
        (1.02, .42, 2, .96), (1.03, .24, 4, .90), (1.04, .10, 6, .84),
    ],
    "vfx_levelup_glow": [
        (.60, .10, 32, .86), (.66, .22, 26, .92), (.72, .38, 20, .97),
        (.79, .58, 14, 1.02), (.86, .78, 8, 1.07), (.92, .94, 3, 1.10),
        (.96, 1.00, 0, 1.12), (.99, .86, -4, 1.08), (1.01, .68, -8, 1.03),
        (1.02, .46, -12, .98), (1.03, .26, -16, .92), (1.04, .10, -20, .86),
    ],
}


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _remove_spill(image: Image.Image, sequence_id: str) -> Image.Image:
    rgba = np.asarray(image.convert("RGBA"), dtype=np.float32).copy()
    red, green, blue, alpha = [rgba[:, :, channel] for channel in range(4)]
    if sequence_id == "vfx_enemy_skill_enrage":
        spill = (alpha > 2.) & (green > red * 1.04 + 8.) & (green > blue * 1.12 + 8.)
        neutral = np.maximum(red, blue)
        green[spill] = neutral[spill] * .74
        alpha[spill] *= .68
    else:
        # The source uses magenta solely as extraction backing. Preserve its
        # intended gold and cyan while neutralizing red+blue fringe residue.
        spill = (alpha > 2.) & (red > green * 1.16 + 10.) & (blue > green * 1.10 + 8.)
        neutral = green * .82
        red[spill] = neutral[spill]
        blue[spill] = neutral[spill]
        alpha[spill] *= .16
        value = np.maximum(np.maximum(red, green), blue)
        minimum = np.minimum(np.minimum(red, green), blue)
        dark_backing = (alpha > 2.) & (value < 118.) & ((value - minimum) < 46.)
        alpha[dark_backing] = 0.
    return Image.fromarray(rgba.clip(0, 255).astype(np.uint8))


def _fit(image: Image.Image, fill: float = .74) -> Image.Image:
    box = image.getbbox()
    if box is None:
        raise RuntimeError("empty rendered VFX master")
    cropped = image.crop(box)
    scale = min(512 * fill / cropped.width, 512 * fill / cropped.height)
    cropped = cropped.resize(
        (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", (512, 512))
    canvas.alpha_composite(cropped, ((512 - cropped.width) // 2, (512 - cropped.height) // 2))
    return canvas


def _open_actor_core(image: Image.Image) -> Image.Image:
    """Cut a soft body-shaped window so the rage aura never replaces its owner."""
    rgba = np.asarray(image.convert("RGBA"), dtype=np.float32).copy()
    yy, xx = np.mgrid[0:512, 0:512]
    radius = np.sqrt(((xx - 256.0) / 180.0) ** 2 + ((yy - 282.0) / 210.0) ** 2)
    # Preserve a trace of internal fire while keeping the body readable. The
    # 0.48-1.12 feather avoids a visibly geometric cutout at phone scale.
    feather = np.clip((radius - .48) / .64, 0.0, 1.0)
    rgba[:, :, 3] *= feather
    return Image.fromarray(rgba.clip(0, 255).astype(np.uint8))


def _frame(master: Image.Image, phase: tuple[float, float, int, float], sequence_id: str) -> Image.Image:
    scale, opacity, offset_y, brightness = phase
    base = _fit(master)
    if sequence_id == "vfx_enemy_skill_enrage":
        base = _open_actor_core(base)
    side = max(1, round(512 * scale))
    layer = base.resize((side, side), Image.Resampling.LANCZOS)
    layer = ImageEnhance.Brightness(layer).enhance(brightness)
    layer.putalpha(layer.getchannel("A").point(lambda value: round(value * opacity)))
    canvas = Image.new("RGBA", (512, 512))
    canvas.alpha_composite(layer, ((512 - side) // 2, (512 - side) // 2 + offset_y))
    return canvas


def main() -> None:
    missing = [path for path in MASTERS.values() if not path.exists()]
    if missing:
        raise FileNotFoundError(f"missing App Store VFX masters: {missing}")
    entries: list[dict] = []
    peaks: list[tuple[str, Image.Image]] = []
    for sequence_id, master_path in MASTERS.items():
        master = _remove_spill(Image.open(master_path).convert("RGBA"), sequence_id)
        output = SEQUENCE_ROOT / sequence_id
        output.mkdir(parents=True, exist_ok=True)
        frame_paths: list[str] = []
        rendered: list[Image.Image] = []
        for index, phase in enumerate(PHASES[sequence_id], 1):
            frame = _frame(master, phase, sequence_id)
            path = output / f"{sequence_id}_{index:02d}.png"
            frame.save(path, optimize=True)
            frame_paths.append(str(path.relative_to(ROOT / "assets/production")))
            rendered.append(frame)
            entries.append({"path": str(path.relative_to(ROOT)), "kind": "vfx_frame", "sha256": _sha256(path)})
        peak_index = max(range(len(PHASES[sequence_id])), key=lambda i: PHASES[sequence_id][i][1])
        peak = rendered[peak_index]
        peaks.append((sequence_id, peak))
        static_path = SINGLE_ROOT / f"{sequence_id}.png"
        peak.save(static_path, optimize=True)
        entries.append({"path": str(static_path.relative_to(ROOT)), "kind": "vfx_static", "sha256": _sha256(static_path)})
        sequence_path = output / f"{sequence_id}_sequence.json"
        sequence_path.write_text(json.dumps({
            "id": sequence_id,
            "fps": FPS[sequence_id],
            "frames": frame_paths,
            "source": str(master_path.relative_to(ROOT)),
            "integration": (
                "Deep-rendered centered rage aura with body-safe core and no directional jet"
                if sequence_id == "vfx_enemy_skill_enrage"
                else "Deep-rendered coherent gold-cyan ascension column with an open actor center"
            ),
        }, ensure_ascii=False, indent=2) + "\n")
        entries.append({"path": str(sequence_path.relative_to(ROOT)), "kind": "vfx_sequence", "sha256": _sha256(sequence_path)})

    contact = Image.new("RGB", (1024, 512), (6, 12, 20))
    draw = ImageDraw.Draw(contact)
    for index, (sequence_id, peak) in enumerate(peaks):
        x = index * 512
        contact.paste(peak, (x, 0), peak)
        draw.text((x + 18, 478), sequence_id, fill=(220, 238, 246))
    contact.save(CONTACT, quality=94)
    entries.append({"path": str(CONTACT.relative_to(ROOT)), "kind": "verification_contact_sheet", "sha256": _sha256(CONTACT)})
    MANIFEST.write_text(json.dumps({"version": 1, "count": len(entries), "assets": entries}, ensure_ascii=False, indent=2) + "\n")
    print(f"App Store VFX replacements built: {len(entries)} tracked outputs")


if __name__ == "__main__":
    main()
