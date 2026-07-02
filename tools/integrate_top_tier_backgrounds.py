#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
BG_DIR = PROD / "sprites" / "backgrounds"
ENV_DIR = PROD / "environment"
CONTACT_DIR = PROD / "contact_sheets"
SOURCE_DIR = PROD / "source_refs" / "generated"
SOURCE_COPY_DIR = SOURCE_DIR / "top_tier_background_sources_2026_07_01"
SPEC_PATH = SOURCE_DIR / "top_tier_background_render_spec_2026_07_01.json"
CONTACT_PATH = CONTACT_DIR / "contact_top_tier_backgrounds_2026_07_01.png"

GAME_SIZE = (1080, 1920)
PHONE_SIZE = (1206, 2622)


@dataclass(frozen=True)
class BackgroundSource:
    env_id: str
    bg_name: str
    title: str
    level_range: str
    imagegen_path: Path
    palette: str
    prompt_brief: str


BACKGROUND_SOURCES = [
    BackgroundSource(
        "env_lava_foundry",
        "bg_lava_foundry",
        "Lava Foundry",
        "001-010",
        Path("/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/ig_045d7fbf356b27ec016a45278d92e0819199b0743cab380e8e.png"),
        "molten orange, amber, char black",
        "High-angle 3D-rendered molten metal foundry with a clear vertical battle lane and bottom barricade.",
    ),
    BackgroundSource(
        "env_glacier_pass",
        "bg_glacier_pass",
        "Glacier Pass",
        "011-020",
        Path("/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/ig_045d7fbf356b27ec016a45282eb0e88191ae6546823a9e3ccd.png"),
        "cold cyan, steel blue, snow white",
        "High-angle 3D-rendered frozen bridge and icebound highway with a clear vertical battle lane.",
    ),
    BackgroundSource(
        "env_abandoned_factory",
        "bg_abandoned_factory",
        "Abandoned Factory",
        "021-030",
        Path("/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/ig_045d7fbf356b27ec016a452903e2148191b8dbaa7814be98c1.png"),
        "rust orange, cold teal, grimy gray",
        "High-angle 3D-rendered derelict factory floor with machinery flanking a readable concrete combat lane.",
    ),
    BackgroundSource(
        "env_toxic_biolab",
        "bg_toxic_biolab",
        "Toxic Biolab",
        "031-040",
        Path("/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/ig_045d7fbf356b27ec016a45296f06048191a936f48a05d9bacb.png"),
        "radioactive green, acid yellow, wet lab gray",
        "High-angle 3D-rendered biohazard lab with toxic containment tanks and a clear grated combat lane.",
    ),
    BackgroundSource(
        "env_storm_substation",
        "bg_storm_substation",
        "Storm Substation",
        "041-050",
        Path("/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/ig_045d7fbf356b27ec016a4529b51368819193d8efa2f17043e8.png"),
        "electric yellow, violet arcs, storm blue",
        "High-angle 3D-rendered electrical substation in rain with lightning arcs and a wet central lane.",
    ),
    BackgroundSource(
        "env_flooded_subway",
        "bg_flooded_subway",
        "Flooded Subway",
        "051-060",
        Path("/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/ig_045d7fbf356b27ec016a452a39f1288191b3eaf040550f5722.png"),
        "cold cyan water, amber lamps, corroded metal",
        "High-angle 3D-rendered flooded metro station with reflective water and a readable track lane.",
    ),
    BackgroundSource(
        "env_desert_refinery",
        "bg_desert_refinery",
        "Desert Refinery",
        "061-070",
        Path("/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/ig_00f673e3b3429be0016a452b1c41008191921c00905b1f4953.png"),
        "sand amber, burned orange, dark oil metal",
        "High-angle 3D-rendered sandstorm oil refinery with side machinery and a vertical sand-swept combat road.",
    ),
    BackgroundSource(
        "env_void_cathedral",
        "bg_void_cathedral",
        "Void Cathedral",
        "071-080",
        Path("/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/ig_00f673e3b3429be0016a452ba2d50c819196c02febd04d50ff.png"),
        "void violet, magenta, black obsidian",
        "High-angle 3D-rendered collapsed cathedral with void rifts and a readable cracked-stone lane.",
    ),
    BackgroundSource(
        "env_orbital_ruins",
        "bg_orbital_ruins",
        "Orbital Ruins",
        "081-090",
        Path("/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/ig_00f673e3b3429be0016a452c1fcde4819188565e351e4b1311.png"),
        "blue-white, dark steel, orange beacons",
        "High-angle 3D-rendered space-elevator ruins with severed cables and a metal-grate combat lane.",
    ),
    BackgroundSource(
        "env_apex_core",
        "bg_apex_core",
        "Apex Core",
        "091-099",
        Path("/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/ig_00f673e3b3429be0016a452cb4a0a481919192d6d406374c4a.png"),
        "molten gold, cyan plasma, black armor",
        "High-angle 3D-rendered final reactor core chamber with black-gold armored lane and plasma machinery.",
    ),
]


def load_font(size: int) -> ImageFont.ImageFont:
    for path in (
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def cover_image(image: Image.Image, size: tuple[int, int], focus: tuple[float, float] = (0.5, 0.52)) -> Image.Image:
    return ImageOps.fit(image.convert("RGB"), size, method=Image.Resampling.LANCZOS, centering=focus).convert("RGBA")


def apply_game_readability_grade(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = ImageEnhance.Contrast(image).enhance(1.08)
    image = ImageEnhance.Color(image).enhance(1.04)
    width, height = size
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Runtime backgrounds need the middle lane to stay readable under enemies,
    # projectiles, damage numbers, and touch aiming feedback.
    lane = [
        (int(width * 0.34), 0),
        (int(width * 0.66), 0),
        (int(width * 0.82), height),
        (int(width * 0.18), height),
    ]
    draw.polygon(lane, fill=(0, 0, 0, 26))
    draw.rectangle((0, 0, width, int(height * 0.18)), fill=(0, 0, 0, 38))
    draw.rectangle((0, int(height * 0.82), width, height), fill=(0, 0, 0, 46))
    draw.rectangle((0, 0, int(width * 0.08), height), fill=(0, 0, 0, 32))
    draw.rectangle((int(width * 0.92), 0, width, height), fill=(0, 0, 0, 32))

    vignette = Image.new("L", size, 0)
    vd = ImageDraw.Draw(vignette)
    for inset, alpha in ((0, 150), (50, 105), (110, 62), (190, 24)):
        vd.rectangle((inset, inset, width - inset, height - inset), outline=alpha, width=42)
    blurred = vignette.filter(ImageFilter.GaussianBlur(64))
    black = Image.new("RGBA", size, (0, 0, 0, 0))
    black.putalpha(blurred)
    return Image.alpha_composite(Image.alpha_composite(image, overlay), black)


def make_layout_guide(background: Image.Image, source: BackgroundSource) -> Image.Image:
    image = background.convert("RGBA")
    width, height = image.size
    tint = Image.new("RGBA", image.size, (0, 0, 0, 96))
    image = Image.alpha_composite(image, tint)
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    font = load_font(42)
    small = load_font(28)

    lane = [
        (int(width * 0.34), int(height * 0.06)),
        (int(width * 0.66), int(height * 0.06)),
        (int(width * 0.80), int(height * 0.82)),
        (int(width * 0.20), int(height * 0.82)),
    ]
    draw.polygon(lane, fill=(76, 210, 255, 44), outline=(120, 230, 255, 210))
    draw.rectangle(
        (int(width * 0.05), int(height * 0.05), int(width * 0.95), int(height * 0.16)),
        outline=(255, 198, 64, 220),
        width=4,
    )
    draw.rectangle(
        (int(width * 0.08), int(height * 0.72), int(width * 0.92), int(height * 0.94)),
        outline=(255, 198, 64, 220),
        width=4,
    )
    for y in (0.25, 0.50, 0.75):
        yy = int(height * y)
        draw.line((int(width * 0.14), yy, int(width * 0.86), yy), fill=(255, 255, 255, 110), width=2)
    draw.text((int(width * 0.08), int(height * 0.065)), f"{source.title} {source.level_range}", fill=(255, 232, 190, 245), font=font)
    draw.text((int(width * 0.08), int(height * 0.165)), "Spawn / readability guide", fill=(210, 234, 244, 225), font=small)
    draw.text((int(width * 0.10), int(height * 0.86)), "Bottom turret / HUD-safe defense area", fill=(210, 234, 244, 225), font=small)
    return Image.alpha_composite(image, layer)


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def build_contact(rows: list[dict[str, str]]) -> None:
    thumb_size = (236, 420)
    pad = 18
    label_h = 74
    cols = 5
    rows_count = 2
    width = cols * thumb_size[0] + (cols + 1) * pad
    height = rows_count * (thumb_size[1] + label_h) + (rows_count + 1) * pad
    sheet = Image.new("RGB", (width, height), (13, 18, 24))
    draw = ImageDraw.Draw(sheet)
    title_font = load_font(24)
    small_font = load_font(18)
    for i, row in enumerate(rows):
        x = pad + (i % cols) * (thumb_size[0] + pad)
        y = pad + (i // cols) * (thumb_size[1] + label_h + pad)
        image = Image.open(ROOT / row["battle_background"]).convert("RGB")
        thumb = ImageOps.fit(image, thumb_size, method=Image.Resampling.LANCZOS)
        sheet.paste(thumb, (x, y))
        draw.rectangle((x, y, x + thumb_size[0] - 1, y + thumb_size[1] - 1), outline=(99, 116, 132), width=2)
        draw.text((x, y + thumb_size[1] + 8), row["title"], fill=(244, 246, 248), font=title_font)
        draw.text((x, y + thumb_size[1] + 38), row["level_range"], fill=(156, 174, 188), font=small_font)
    CONTACT_DIR.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT_PATH, quality=95)


def update_index(rows: list[dict[str, str]]) -> None:
    index_path = PROD / "OUTSOURCER_ASSET_INDEX.json"
    data = json.loads(index_path.read_text(encoding="utf-8"))
    data.setdefault("owner_directed_generated_overrides", [])
    source_ref = "source_refs/generated/top_tier_background_render_spec_2026_07_01.json"
    data["owner_directed_generated_overrides"] = [
        item
        for item in data["owner_directed_generated_overrides"]
        if not (item.get("source") == source_ref and item.get("path") in {"sprites/backgrounds", "environment"})
    ]
    data["owner_directed_generated_overrides"].extend(
        [
            {
                "path": "sprites/backgrounds",
                "source": source_ref,
                "derived": "contact_sheets/contact_top_tier_backgrounds_2026_07_01.png",
                "reason": "Owner requested campaign environments to be raised to top-tier rendered App Store quality with no vector/SVG placeholder treatment; battle background paths and env IDs are preserved.",
            },
            {
                "path": "environment",
                "source": source_ref,
                "derived": "contact_sheets/contact_top_tier_backgrounds_2026_07_01.png",
                "reason": "Generated matching 1206x2622 portrait crops and development-only battle layout guides from the top-tier rendered environment sources.",
            },
        ]
    )
    counts = data.setdefault("counts", {})
    counts["background_files"] = len(list((PROD / "sprites" / "backgrounds").glob("*.png")))
    counts["environment_files"] = len(list((PROD / "environment").glob("*.png")))
    counts["total_files"] = len([p for p in PROD.rglob("*") if p.is_file() and not p.name.endswith(".import")])
    index_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    SOURCE_COPY_DIR.mkdir(parents=True, exist_ok=True)
    rows: list[dict[str, str]] = []
    for source in BACKGROUND_SOURCES:
        if not source.imagegen_path.exists():
            raise FileNotFoundError(f"missing generated source image: {source.imagegen_path}")
        source_copy = SOURCE_COPY_DIR / f"{source.bg_name}_imagegen_source.png"
        shutil.copy2(source.imagegen_path, source_copy)
        source_image = Image.open(source_copy).convert("RGB")

        battle = apply_game_readability_grade(cover_image(source_image, GAME_SIZE), GAME_SIZE)
        portrait = apply_game_readability_grade(cover_image(source_image, PHONE_SIZE), PHONE_SIZE)
        layout = make_layout_guide(portrait, source)

        battle_path = BG_DIR / f"{source.bg_name}.png"
        portrait_path = ENV_DIR / f"{source.bg_name}_portrait.png"
        guide_path = ENV_DIR / f"{source.bg_name}_battle_layout_guide.png"
        save_png(battle, battle_path)
        save_png(portrait, portrait_path)
        save_png(layout, guide_path)

        rows.append(
            {
                "env_id": source.env_id,
                "title": source.title,
                "level_range": source.level_range,
                "battle_background": str(battle_path.relative_to(ROOT)),
                "portrait": str(portrait_path.relative_to(ROOT)),
                "layout_guide": str(guide_path.relative_to(ROOT)),
                "source_copy": str(source_copy.relative_to(ROOT)),
                "imagegen_default_source": str(source.imagegen_path),
                "palette": source.palette,
                "prompt_brief": source.prompt_brief,
            }
        )

    build_contact(rows)
    spec = {
        "id": "top_tier_background_render_pass_2026_07_01",
        "generated_by": "built-in image_gen + tools/integrate_top_tier_backgrounds.py",
        "quality_target": "Top-tier 3D-rendered mobile game environment art; no SVG, no vector placeholder, no flat icon treatment.",
        "preserved_contracts": [
            "Existing env IDs and data/environments.json paths are unchanged.",
            "Battle backgrounds remain 1080x1920 for the current gameplay canvas.",
            "Portrait and battle layout guide assets remain 1206x2622 for iPhone full-screen review assets.",
            "No gameplay logic, level mapping, economy, or enemy data changed.",
        ],
        "rejected_alternates": [
            {
                "env_id": "env_desert_refinery",
                "path": "/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/ig_045d7fbf356b27ec016a452a9927a08191843b4a0d4b64fc6e.png",
                "reason": "Kept as unused alternate; the selected retry has stronger refinery landmarks and better bottom barricade readability.",
            }
        ],
        "outputs": rows,
        "contact_sheet": str(CONTACT_PATH.relative_to(ROOT)),
    }
    SPEC_PATH.parent.mkdir(parents=True, exist_ok=True)
    SPEC_PATH.write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    update_index(rows)
    print(f"Integrated {len(rows)} top-tier rendered campaign backgrounds")
    print(CONTACT_PATH.relative_to(ROOT))
    print(SPEC_PATH.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
