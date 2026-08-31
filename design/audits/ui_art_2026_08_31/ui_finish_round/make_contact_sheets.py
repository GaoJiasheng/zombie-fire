#!/usr/bin/env python3
"""Build owner-facing contact sheets from checked-in visual evidence."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
OLD = ROOT / "design/audits/ui_art_2026_08_30"


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/STHeiti Medium.ttc",
    ):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def fitted(path: Path, size: tuple[int, int]) -> Image.Image:
    with Image.open(path) as source:
        return ImageOps.fit(source.convert("RGB"), size, method=Image.Resampling.LANCZOS)


def before_after() -> None:
    rows = [
        (
            "设置：重型按钮 → 开关控件",
            OLD / "round2_regression_2026_08_30/round2_1080x1920_zh_settings.png",
            HERE / "after_1080x1920/settings.png",
        ),
        (
            "主菜单：slogan 下移贴近操作组",
            OLD / "round2_regression_2026_08_30/round2_1080x1920_zh_menu.png",
            HERE / "after_1080x1920/menu.png",
        ),
        (
            "地图：锁定措辞 + 暖色战区层",
            OLD / "round2_regression_2026_08_30/round2_1080x1920_zh_map.png",
            HERE / "after_1080x1920/map.png",
        ),
        (
            "收藏：零资源弱化 + 锁定加成澄清",
            OLD / "round2_regression_2026_08_30/round2_1080x1920_zh_collection.png",
            HERE / "after_1080x1920_zero_resources/zh_collection.png",
        ),
        (
            "配装：星徽刻度 + 三色语义摘要",
            OLD / "device_matrix_phase2/device_matrix_iphone16_pro_loadout.png",
            HERE / "after_1080x1920/loadout.png",
        ),
    ]
    thumb = (270, 480)
    header = 52
    gap = 18
    canvas = Image.new("RGB", (thumb[0] * 2 + gap * 3, (thumb[1] + header + gap) * len(rows) + gap), "#0b1014")
    draw = ImageDraw.Draw(canvas)
    draw.text((gap, 10), "改前", fill="#9ba8ad", font=font(24))
    draw.text((gap * 2 + thumb[0], 10), "改后", fill="#f1b35d", font=font(24))
    y = gap
    for label, before, after in rows:
        y += header
        canvas.paste(fitted(before, thumb), (gap, y))
        canvas.paste(fitted(after, thumb), (gap * 2 + thumb[0], y))
        draw.text((gap, y - 38), label, fill="#e9eee9", font=font(21))
        y += thumb[1] + gap
    canvas.save(HERE / "before_after_key_screens.png", optimize=True)


def after_matrix() -> None:
    screens = ["menu", "map", "loadout", "collection", "settings"]
    rows = [
        ("1080×1920 中文", HERE / "after_1080x1920", "zh"),
        ("1080×1920 English", HERE / "after_1080x1920", "en"),
        ("1320×2868 中文", HERE / "after_1320x2868", "zh"),
        ("1320×2868 English", HERE / "after_1320x2868", "en"),
        ("750×1334 中文", HERE / "after_750x1334", "zh"),
        ("750×1334 English", HERE / "after_750x1334", "en"),
    ]
    thumb = (180, 320)
    left = 190
    header = 46
    gap = 12
    canvas = Image.new("RGB", (left + len(screens) * (thumb[0] + gap) + gap, header + len(rows) * (thumb[1] + gap) + gap), "#0b1014")
    draw = ImageDraw.Draw(canvas)
    for index, screen in enumerate(screens):
        draw.text((left + index * (thumb[0] + gap), 10), screen, fill="#f1b35d", font=font(20))
    for row_index, (label, directory, language) in enumerate(rows):
        y = header + row_index * (thumb[1] + gap)
        draw.text((12, y + 8), label, fill="#d8e1e1", font=font(19))
        for column, screen in enumerate(screens):
            if directory.name == "after_1080x1920":
                name = f"{screen}{'_en' if language == 'en' else ''}.png"
                if screen == "collection":
                    name = f"collection_chips{'_en' if language == 'en' else ''}.png"
            else:
                name = f"{language}_{screen}.png"
            x = left + column * (thumb[0] + gap)
            canvas.paste(fitted(directory / name, thumb), (x, y))
    canvas.save(HERE / "three_size_bilingual_after_contact_sheet.png", optimize=True)


def zero_resources() -> None:
    directory = HERE / "after_1080x1920_zero_resources"
    screens = ["map", "loadout", "collection"]
    thumb = (270, 480)
    gap = 14
    header = 56
    canvas = Image.new("RGB", (len(screens) * (thumb[0] + gap) + gap, 2 * (thumb[1] + header + gap) + gap), "#0b1014")
    draw = ImageDraw.Draw(canvas)
    for row, language in enumerate(("zh", "en")):
        y = gap + row * (thumb[1] + header + gap)
        draw.text((gap, y), "零资源中文" if language == "zh" else "Zero-resource English", fill="#d8e1e1", font=font(23))
        for column, screen in enumerate(screens):
            x = gap + column * (thumb[0] + gap)
            canvas.paste(fitted(directory / f"{language}_{screen}.png", thumb), (x, y + header))
    canvas.save(HERE / "zero_resources_contact_sheet.png", optimize=True)


if __name__ == "__main__":
    before_after()
    after_matrix()
    zero_resources()
