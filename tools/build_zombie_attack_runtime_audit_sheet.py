#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "tmp/zombie_attack_runtime_audit_2026_07_26"
SHEET = OUT_DIR / "contact_sheet.png"


def godot_executable() -> str:
    configured = os.environ.get("GODOT_BIN")
    if configured:
        return configured
    return shutil.which("godot") or "/opt/homebrew/bin/godot"


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        ROOT / "assets/production/fonts/font_main.ttf",
        Path("/System/Library/Fonts/PingFang.ttc"),
    ):
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def capture(group: int) -> Path:
    output = OUT_DIR / f"group_{group + 1}.png"
    payload = {
        "level_id": "level_001",
        "debug_zombie_attack_showcase": group,
        "warmup_frames": 4,
    }
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
    if (
        process.returncode != 0
        or "SCRIPT ERROR:" in process.stdout
        or not output.exists()
    ):
        raise RuntimeError(f"Godot zombie attack capture failed: group {group + 1}")
    return output


def compose(captures: list[Path]) -> None:
    cell_w = 540
    cell_h = 1010
    header_h = 72
    margin = 24
    canvas = Image.new(
        "RGB",
        (cell_w * 2 + margin * 3, cell_h * 2 + margin * 3),
        (6, 10, 13),
    )
    draw = ImageDraw.Draw(canvas)
    heading = font(27)
    caption = font(18)
    groups = [
        "01–05  游荡 / 奔袭 / 重击 / 爆裂 / 尖啸",
        "06–10  腐蚀 / 伏地 / 重甲 / 盾卫 / 跃击",
        "11–15  破城 / 相位 / 召唤 / 毒化 / 冲锋",
        "16–20  再生 / 分裂 / 守望 / 突变 / 狂暴",
    ]
    for index, (path, label) in enumerate(zip(captures, groups)):
        source = Image.open(path).convert("RGB")
        max_w = cell_w - 18
        max_h = cell_h - header_h - 18
        scale = min(max_w / source.width, max_h / source.height)
        preview = source.resize(
            (round(source.width * scale), round(source.height * scale)),
            Image.Resampling.LANCZOS,
        )
        col, row = index % 2, index // 2
        x = margin + col * (cell_w + margin)
        y = margin + row * (cell_h + margin)
        draw.rounded_rectangle(
            (x, y, x + cell_w, y + cell_h),
            16,
            fill=(12, 19, 24),
            outline=(48, 126, 143),
            width=2,
        )
        draw.text((x + 16, y + 10), label, font=heading, fill=(222, 243, 247))
        draw.text(
            (x + 16, y + 44),
            "左：预备　中：命中（第 4 帧）　右：收招",
            font=caption,
            fill=(108, 198, 215),
        )
        canvas.paste(
            preview,
            (
                x + (cell_w - preview.width) // 2,
                y + header_h + (max_h - preview.height) // 2,
            ),
        )
    canvas.save(SHEET)
    print(f"zombie attack runtime audit sheet: {SHEET}")


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    captures = [capture(group) for group in range(4)]
    compose(captures)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
