#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "tmp/status_vfx_runtime_audit_2026_07_26"
SHEET = OUT_DIR / "contact_sheet.png"


def godot_executable() -> str:
    configured = os.environ.get("GODOT_BIN")
    if configured:
        return configured
    discovered = shutil.which("godot")
    if discovered:
        return discovered
    return "/opt/homebrew/bin/godot"


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        ROOT / "assets/production/fonts/font_main.ttf",
        Path("/System/Library/Fonts/PingFang.ttc"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def capture(name: str, payload: dict) -> Path:
    output = OUT_DIR / f"{name}.png"
    command = [
        godot_executable(),
        "--path",
        ".",
        "--script",
        "res://tools/_shot.gd",
        "--",
        "battle",
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        str(output),
    ]
    process = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    print(process.stdout, end="")
    if process.returncode != 0 or "SCRIPT ERROR:" in process.stdout:
        raise RuntimeError(f"Godot capture failed: {name}")
    if not output.exists():
        raise RuntimeError(f"Godot capture missing output: {output}")
    return output


def compose(cases: list[tuple[str, Path]]) -> None:
    cell_width = 540
    cell_height = 1020
    header_height = 64
    margin = 24
    sheet = Image.new(
        "RGB",
        (cell_width * 2 + margin * 3, cell_height * 2 + margin * 3),
        (8, 12, 17),
    )
    draw = ImageDraw.Draw(sheet)
    label_font = font(30)
    meta_font = font(20)
    for index, (label, path) in enumerate(cases):
        source = Image.open(path).convert("RGB")
        max_width = cell_width - 20
        max_height = cell_height - header_height - 20
        scale = min(max_width / source.width, max_height / source.height)
        resized = source.resize(
            (round(source.width * scale), round(source.height * scale)),
            Image.Resampling.LANCZOS,
        )
        column = index % 2
        row = index // 2
        x = margin + column * (cell_width + margin)
        y = margin + row * (cell_height + margin)
        draw.rounded_rectangle(
            (x, y, x + cell_width, y + cell_height),
            radius=18,
            fill=(13, 20, 28),
            outline=(48, 118, 136),
            width=2,
        )
        draw.text((x + 18, y + 12), label, font=label_font, fill=(224, 246, 251))
        draw.text(
            (x + cell_width - 154, y + 20),
            f"{source.width}×{source.height}",
            font=meta_font,
            fill=(118, 183, 198),
        )
        image_x = x + (cell_width - resized.width) // 2
        image_y = y + header_height + (max_height - resized.height) // 2
        sheet.paste(resized, (image_x, image_y))
    sheet.save(SHEET)
    print(f"status VFX runtime audit sheet: {SHEET}")


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    base = {"level_id": "level_001", "warmup_frames": 8}
    capture_specs = [
        ("四种单状态", "single", {}),
        ("多状态叠加 + Boss", "stacked", {}),
        ("36 怪信息密度", "dense", {}),
        ("高屏安全区", "single", {"viewport_size": [1080, 2348]}),
    ]
    rendered: list[tuple[str, Path]] = []
    for label, mode, extra in capture_specs:
        payload = dict(base)
        payload["debug_status_vfx_showcase"] = mode
        payload.update(extra)
        rendered.append((label, capture(mode + ("_tall" if extra else ""), payload)))
    compose(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
