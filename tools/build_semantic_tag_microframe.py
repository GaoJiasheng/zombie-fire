#!/usr/bin/env python3
"""Build the texture-backed, scale-safe semantic tag micro-frame.

The source is intentionally restrained: one continuous edge, one deep neutral
surface and no corner jewels, scan lines or directional highlights. Runtime
nine-slicing keeps the corners at authored density while UiKit tints the neutral
master with each theme's data-owned semantic palette.
"""

from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/production/sprites/ui/ui_semantic_tag_microframe_v2.png"
INDEX_PATH = ROOT / "assets/production/OUTSOURCER_ASSET_INDEX.json"
SPEC_PATH = "source_refs/generated/semantic_tag_microframe_v2_2026_08_03/spec.md"


def build() -> None:
    scale = 4
    width, height = 96, 48
    canvas = Image.new("RGBA", (width * scale, height * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    def box(inset: int, y_offset: int = 0) -> tuple[int, int, int, int]:
        return (
            inset * scale,
            (inset + y_offset) * scale,
            (width - inset - 1) * scale,
            (height - inset - 1 + y_offset) * scale,
        )

    # The shadow is contained inside the source canvas so no glow can be cut by
    # a small tag's Control rect.
    draw.rounded_rectangle(box(3, 1), radius=11 * scale, fill=(0, 0, 0, 112))
    draw.rounded_rectangle(
        box(2),
        radius=11 * scale,
        fill=(17, 19, 21, 248),
        outline=(255, 255, 255, 244),
        width=2 * scale,
    )
    # A very quiet inner keyline holds up after downsampling without creating
    # the broken underline/corner sparkle of the rejected ornamental version.
    draw.rounded_rectangle(
        box(5),
        radius=8 * scale,
        outline=(116, 122, 126, 82),
        width=1 * scale,
    )

    image = canvas.resize((width, height), Image.Resampling.LANCZOS)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT, optimize=True)


def register() -> None:
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    rows = data.setdefault("owner_directed_generated_overrides", [])
    task = "Texture-backed restrained semantic tag micro-frame"
    rows[:] = [row for row in rows if row.get("task") != task]
    rows.append(
        {
            "path": "sprites/ui/ui_semantic_tag_microframe_v2.png",
            "source": [SPEC_PATH, "../../tools/build_semantic_tag_microframe.py"],
            "reason": (
                "The first small-tag ornamental frame compressed into disconnected highlights. "
                "This deterministic neutral master preserves one continuous edge, quiet inner keyline "
                "and contained shadow under nine-slice scaling; runtime theme tint remains data-owned."
            ),
            "count": 1,
            "task": task,
            "created_at": datetime.now(timezone(timedelta(hours=8))).isoformat(timespec="seconds"),
        }
    )
    INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    build()
    register()
    print(OUTPUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
