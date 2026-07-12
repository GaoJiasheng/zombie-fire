#!/usr/bin/env python3
from __future__ import annotations

import math
import random
import shutil
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
UI_DIR = ROOT / "assets" / "production" / "sprites" / "ui"
SOURCE_REF_DIR = ROOT / "assets" / "production" / "source_refs" / "generated"
CONTACT_DIR = ROOT / "assets" / "production" / "contact_sheets"
USER_REFERENCE = (
    Path("/tmp/codex-remote-attachments")
    / "019f1c90-6388-7e23-89ec-5759e03c6022"
    / "9686F21B-F728-4C97-A363-57ABF71587B7"
    / "1-粘贴的图片-1.jpg"
)
MODEL_REFERENCE = (
    Path.home()
    / ".codex"
    / "generated_images"
    / "019f1c90-6388-7e23-89ec-5759e03c6022"
    / "ig_06b6fa14841e1f26016a4eec5cb05481918a2c79ce0eb27348.png"
)


SIZES: list[tuple[int, int]] = [
    (154, 44),
    (166, 58),
    (170, 84),
    (172, 44),
    (174, 72),
    (176, 76),
    (236, 96),
    (260, 112),
    (268, 48),
    (286, 72),
    (286, 80),
    (286, 112),
    (320, 74),
    (320, 80),
    (412, 88),
    (432, 88),
    (440, 80),
    (440, 88),
    (444, 88),
    (452, 88),
    (484, 102),
    (512, 160),
    (560, 104),
    (600, 120),
    (760, 88),
    (760, 112),
    (780, 148),
    (784, 96),
    (840, 88),
    (880, 88),
    (880, 96),
    (904, 88),
    (920, 88),
    (980, 58),
    (980, 96),
    (980, 100),
]


def _load(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def _alpha_paste(dst: Image.Image, src: Image.Image, xy: tuple[int, int]) -> None:
    dst.alpha_composite(src, xy)


def _blend_over_alpha(base: Image.Image, color: tuple[int, int, int], amount: float) -> Image.Image:
    rgb = Image.new("RGBA", base.size, (*color, 255))
    alpha = base.getchannel("A").point(lambda a: int(a * amount))
    rgb.putalpha(alpha)
    return Image.alpha_composite(base, rgb)


def _tile_center(center_src: Image.Image, width: int, height: int, seed: int) -> Image.Image:
	if width <= 0:
		return Image.new("RGBA", (0, height), (0, 0, 0, 0))
	rng = random.Random(seed)
	out = center_src.resize((width, height), Image.Resampling.BICUBIC)
	alpha = out.getchannel("A")

	# Break up any resized-center softness with continuous, low-frequency brushed-metal variation.
	noise_small_w = max(16, width // 18)
	noise_small_h = max(8, height // 8)
	noise = Image.effect_noise((noise_small_w, noise_small_h), 22).convert("L")
	noise = noise.resize((width, height), Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(max(0.4, height / 90.0)))
	noise_alpha = alpha.point(lambda a: int(a * 0.045))
	noise_rgba = Image.merge("RGBA", (noise, noise, noise, noise_alpha))
	out = Image.alpha_composite(out, noise_rgba)

	detail = Image.new("RGBA", (width, height), (0, 0, 0, 0))
	draw = ImageDraw.Draw(detail)
	for _ in range(max(1, width // 260)):
		y = rng.randint(int(height * 0.28), int(height * 0.70))
		x0 = rng.randint(int(width * 0.08), max(int(width * 0.08), int(width * 0.86)))
		x1 = min(width - 1, x0 + rng.randint(max(10, width // 50), max(18, width // 18)))
		shade = rng.randint(74, 118)
		draw.line([(x0, y), (x1, y + rng.randint(-1, 1))], fill=(shade, shade, shade, rng.randint(8, 18)), width=1)
	return Image.alpha_composite(out, detail)


def _extract_reference_buttons(reference_path: Path) -> list[Image.Image]:
	if not reference_path.exists():
		raise FileNotFoundError(reference_path)
	source = Image.open(reference_path).convert("RGB")
	pixels = source.load()
	w, h = source.size
	mask: list[list[bool]] = [[False] * w for _ in range(h)]
	for y in range(h):
		for x in range(w):
			r, g, b = pixels[x, y]
			is_green = g > 130 and r < 120 and b < 120 and g > r * 1.45 and g > b * 1.45
			mask[y][x] = not is_green

	seen: list[list[bool]] = [[False] * w for _ in range(h)]
	boxes: list[tuple[int, int, int, int, int]] = []
	for y in range(h):
		for x in range(w):
			if seen[y][x] or not mask[y][x]:
				continue
			stack = [(x, y)]
			seen[y][x] = True
			xs: list[int] = []
			ys: list[int] = []
			while stack:
				cx, cy = stack.pop()
				xs.append(cx)
				ys.append(cy)
				for nx in range(cx - 1, cx + 2):
					for ny in range(cy - 1, cy + 2):
						if nx < 0 or ny < 0 or nx >= w or ny >= h:
							continue
						if seen[ny][nx] or not mask[ny][nx]:
							continue
						seen[ny][nx] = True
						stack.append((nx, ny))
			if len(xs) > 1000:
				boxes.append((len(xs), min(xs), min(ys), max(xs) + 1, max(ys) + 1))
	if len(boxes) < 4:
		raise RuntimeError(f"expected at least 4 button crops from {reference_path}, found {len(boxes)}")
	boxes = sorted(boxes, key=lambda box: (box[2], box[1]))
	buttons: list[Image.Image] = []
	for _, x0, y0, x1, y1 in boxes:
		pad = 8
		crop = source.crop((max(0, x0 - pad), max(0, y0 - pad), min(w, x1 + pad), min(h, y1 + pad)))
		buttons.append(_remove_green(crop))
	return buttons


def _remove_green(image: Image.Image) -> Image.Image:
	rgba = image.convert("RGBA")
	pixels = rgba.load()
	w, h = rgba.size
	alpha = Image.new("L", (w, h), 255)
	alpha_pixels = alpha.load()
	for y in range(h):
		for x in range(w):
			r, g, b, _ = pixels[x, y]
			max_rb = max(r, b)
			green_score = max(0, g - max_rb)
			key_like = g > 95 and green_score > 24 and g > r * 1.18 and g > b * 1.18
			if key_like:
				alpha_pixels[x, y] = max(0, min(255, int((82 - green_score) * 4.4)))
			else:
				alpha_pixels[x, y] = 255
			if green_score > 10 and g > b * 1.04 and g > r * 1.10:
				neutral_g = int(max_rb * 0.72 + min(r, b) * 0.18)
				g = min(g, neutral_g)
			pixels[x, y] = (r, g, b, 255)
	# Contract the matte by one pixel before feathering; this removes JPEG chroma spill
	# around the rendered bevel without changing the button silhouette meaningfully.
	alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.45))
	rgba.putalpha(alpha)
	return rgba


def _source_for_size(buttons: list[Image.Image], width: int, height: int) -> Image.Image:
	target_ratio = float(width) / max(float(height), 1.0)
	def score(button: Image.Image) -> float:
		ratio = float(button.width) / max(float(button.height), 1.0)
		return abs(ratio - target_ratio) + (0.08 if button.width < width and target_ratio > 5.0 else 0.0)
	return min(buttons, key=score)


def _secondary_variant(image: Image.Image) -> Image.Image:
	# Secondary buttons should keep the same premium armored material; disabled state
	# is handled by runtime modulation, not by flattening the texture into grey.
	return ImageEnhance.Contrast(ImageEnhance.Brightness(image).enhance(0.98)).enhance(1.12)


def _soften_warm_cool_transition(image: Image.Image, primary: bool) -> Image.Image:
	# Keep the owner-approved orange/cyan armored lighting, but make it read as
	# rim light on dark metal rather than a hard two-color gradient split.
	w, h = image.size
	alpha = image.getchannel("A")
	out = ImageEnhance.Color(image).enhance(0.84 if primary else 0.78)

	neutral_alpha = Image.new("L", (w, h), 0)
	neutral_pixels = neutral_alpha.load()
	for y in range(h):
		for x in range(w):
			t = x / max(1, w - 1)
			center = 1.0 - min(1.0, abs(t - 0.5) / 0.50)
			wide = 1.0 - min(1.0, abs(t - 0.5) / 0.82)
			amount = 0.04 + center * 0.10 + wide * 0.04
			neutral_pixels[x, y] = int(amount * 255)
	neutral_alpha = neutral_alpha.filter(ImageFilter.GaussianBlur(max(2.0, h / 18.0)))
	neutral_alpha = ImageChops.multiply(neutral_alpha, alpha)
	neutral = Image.new("RGBA", (w, h), (18, 22, 22, 0))
	neutral.putalpha(neutral_alpha)
	out = Image.alpha_composite(out, neutral)

	left_alpha = Image.new("L", (w, h), 0)
	right_alpha = Image.new("L", (w, h), 0)
	lp = left_alpha.load()
	rp = right_alpha.load()
	for y in range(h):
		for x in range(w):
			t = x / max(1, w - 1)
			left = max(0.0, 1.0 - t / 0.78)
			right = max(0.0, (t - 0.22) / 0.78)
			lp[x, y] = int((left ** 2.2) * (22 if primary else 14))
			rp[x, y] = int((right ** 2.2) * (18 if primary else 15))
	left_alpha = left_alpha.filter(ImageFilter.GaussianBlur(max(8.0, h / 8.0)))
	right_alpha = right_alpha.filter(ImageFilter.GaussianBlur(max(8.0, h / 8.0)))
	left_alpha = ImageChops.multiply(left_alpha, alpha)
	right_alpha = ImageChops.multiply(right_alpha, alpha)

	warm = Image.new("RGBA", (w, h), (255, 128, 44, 0))
	warm.putalpha(left_alpha)
	cool = Image.new("RGBA", (w, h), (68, 190, 210, 0))
	cool.putalpha(right_alpha)
	out = Image.alpha_composite(out, warm)
	out = Image.alpha_composite(out, cool)

	detail_strength = 0.052 if w / max(1, h) >= 12.0 else 0.030
	detail = Image.effect_noise((w, h), 24 if detail_strength > 0.04 else 20).convert("L")
	detail_alpha = alpha.point(lambda a: int(a * detail_strength))
	detail_rgba = Image.merge("RGBA", (detail, detail, detail, detail_alpha))
	out = Image.alpha_composite(out, detail_rgba)
	if w / max(1, h) >= 12.0:
		rng = random.Random(w * 211 + h * 397 + (5 if primary else 9))
		scuffs = Image.new("RGBA", (w, h), (0, 0, 0, 0))
		draw = ImageDraw.Draw(scuffs)
		for _ in range(max(34, w // 18)):
			x0 = rng.randint(int(w * 0.08), int(w * 0.90))
			y0 = rng.randint(int(h * 0.22), int(h * 0.78))
			x1 = min(w - 1, x0 + rng.randint(18, max(32, w // 8)))
			shade = rng.randint(72, 156)
			warm_bias = rng.randint(-10, 16)
			cool_bias = rng.randint(-8, 18)
			draw.line(
				[(x0, y0), (x1, y0 + rng.randint(-1, 1))],
				fill=(shade + warm_bias, shade, shade + cool_bias, rng.randint(34, 74)),
				width=1,
			)
		for _ in range(max(80, w // 8)):
			x = rng.randint(int(w * 0.05), int(w * 0.95))
			y = rng.randint(int(h * 0.18), int(h * 0.82))
			shade = rng.randint(72, 170)
			draw.point((x, y), fill=(shade + rng.randint(-8, 10), shade, shade + rng.randint(-5, 14), rng.randint(45, 90)))
		scuffs.putalpha(ImageChops.multiply(scuffs.getchannel("A"), alpha))
		out = Image.alpha_composite(out, scuffs)
		pixels = out.load()
		for _ in range(max(90, w // 9)):
			x0 = rng.randint(int(w * 0.05), int(w * 0.94))
			y0 = rng.randint(int(h * 0.20), int(h * 0.80))
			length = rng.randint(6, max(12, w // 16))
			dr = rng.randint(-18, 18)
			dg = rng.randint(-14, 14)
			db = rng.randint(-18, 18)
			for dx in range(length):
				x = min(w - 1, x0 + dx)
				y = min(h - 1, max(0, y0 + rng.randint(-1, 1)))
				r, g, b, a = pixels[x, y]
				if a <= 32:
					continue
				strength = rng.uniform(0.28, 0.64)
				pixels[x, y] = (
					max(0, min(255, int(r + dr * strength))),
					max(0, min(255, int(g + dg * strength))),
					max(0, min(255, int(b + db * strength))),
					a,
				)
	return ImageEnhance.Contrast(out).enhance(1.08)


def _add_render_detail(img: Image.Image, primary: bool, seed: int) -> Image.Image:
    rng = random.Random(seed)
    w, h = img.size
    alpha = img.getchannel("A")
    detail = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(detail)

    # Long buttons otherwise look empty in the center. Add subtle grime and wear, not vector linework.
    scratch_count = max(3, w // 170)
    for _ in range(scratch_count):
        x = rng.randint(int(w * 0.18), int(w * 0.82))
        y = rng.randint(int(h * 0.25), int(h * 0.72))
        length = rng.randint(max(18, w // 22), max(32, w // 9))
        shade = rng.randint(80, 135)
        draw.line([(x, y), (min(w - 1, x + length), y + rng.randint(-1, 1))], fill=(shade, shade, shade, rng.randint(18, 38)), width=1)

    noise = Image.effect_noise((w, h), 18).convert("L")
    noise_alpha = alpha.point(lambda a: int(a * 0.035))
    noise_rgba = Image.merge("RGBA", (noise, noise, noise, noise_alpha))
    out = Image.alpha_composite(img, detail)
    out = Image.alpha_composite(out, noise_rgba)

    # Reassert the reference's orange/cyan premium material as soft rim light,
    # not as a hard red/blue block split.
    left_glow = Image.new("L", (w, h), 0)
    ld = ImageDraw.Draw(left_glow)
    ld.rectangle((0, 0, int(w * 0.28), h), fill=18 if primary else 10)
    left_glow = left_glow.filter(ImageFilter.GaussianBlur(max(8, h // 8)))
    accent = Image.new("RGBA", (w, h), (255, 128, 34, 0))
    accent.putalpha(ImageChops.multiply(left_glow, alpha))
    out = Image.alpha_composite(out, accent)

    right_glow = Image.new("L", (w, h), 0)
    rd = ImageDraw.Draw(right_glow)
    rd.rectangle((int(w * 0.70), 0, w, h), fill=14)
    right_glow = right_glow.filter(ImageFilter.GaussianBlur(max(8, h // 8)))
    cyan = Image.new("RGBA", (w, h), (62, 200, 220, 0))
    cyan.putalpha(ImageChops.multiply(right_glow, alpha))
    out = Image.alpha_composite(out, cyan)

    enhancer = ImageEnhance.Contrast(out)
    return _soften_warm_cool_transition(enhancer.enhance(1.04), primary)


def render_button(source: Image.Image, width: int, height: int, primary: bool, seed: int) -> Image.Image:
    src_w, src_h = source.size
    scale = height / float(src_h)
    scaled_w = max(2, int(round(src_w * scale)))
    scaled = source.resize((scaled_w, height), Image.Resampling.LANCZOS)

    cap = min(max(int(height * 1.05), 28), max(2, width // 2 - 2), max(2, int(scaled_w * 0.34)))
    center_w = max(0, width - cap * 2)
    left = scaled.crop((0, 0, cap, height))
    right = scaled.crop((scaled_w - cap, 0, scaled_w, height))
    center_src = scaled.crop((cap, 0, max(cap + 1, scaled_w - cap), height))
    center = _tile_center(center_src, center_w, height, seed)

    out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    _alpha_paste(out, center, (cap, 0))
    _alpha_paste(out, left, (0, 0))
    _alpha_paste(out, right, (width - cap, 0))
    return _add_render_detail(out, primary, seed)


def make_contact_sheet(paths: list[Path], out_path: Path) -> None:
    thumbs = []
    for path in paths:
        im = _load(path)
        scale = min(1.0, 300 / max(im.width, 1), 90 / max(im.height, 1))
        thumb = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.Resampling.LANCZOS)
        thumbs.append((path.name, thumb))
    cell_w, cell_h = 340, 126
    cols = 3
    rows = math.ceil(len(thumbs) / cols)
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h), (12, 17, 22))
    draw = ImageDraw.Draw(sheet)
    for idx, (name, thumb) in enumerate(thumbs):
        x = (idx % cols) * cell_w
        y = (idx // cols) * cell_h
        draw.rectangle((x + 6, y + 6, x + cell_w - 6, y + cell_h - 6), outline=(78, 96, 108), width=1)
        sheet.paste(thumb.convert("RGB"), (x + (cell_w - thumb.width) // 2, y + 18), thumb.getchannel("A"))
        draw.text((x + 14, y + 100), name, fill=(218, 224, 220))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path)


def main() -> int:
    SOURCE_REF_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copy2(USER_REFERENCE, SOURCE_REF_DIR / "native_button_reference_owner_2026_07_09.jpg")
    # The owner explicitly rejected the softer model-interpreted sheet. Use the
    # provided armored reference itself as the source of truth and only keep the
    # model master as provenance if it exists.
    reference_path = USER_REFERENCE
    if MODEL_REFERENCE.exists():
        shutil.copy2(MODEL_REFERENCE, SOURCE_REF_DIR / "native_button_model_master_rejected_2026_07_09.png")
    for old_name in ["ui_button_primary.png", "ui_button_secondary.png"]:
        old_path = UI_DIR / old_name
        backup_path = SOURCE_REF_DIR / f"previous_{old_name.replace('.png', '')}_before_owner_reference_2026_07_09.png"
        if old_path.exists() and not backup_path.exists():
            shutil.copy2(old_path, backup_path)

    reference_buttons = _extract_reference_buttons(reference_path)

    written: list[Path] = []
    for width, height in SIZES:
        src = _source_for_size(reference_buttons, width, height)
        for primary, prefix in [(True, "primary"), (False, "secondary")]:
            out = render_button(src, width, height, primary, seed=width * 1009 + height * 917 + (1 if primary else 2))
            if not primary:
                out = _secondary_variant(out)
            path = UI_DIR / f"ui_button_{prefix}_native_{width}x{height}.png"
            out.save(path)
            written.append(path)
            if (width, height) == (512, 160):
                out.save(UI_DIR / f"ui_button_{prefix}.png")

    make_contact_sheet(written, CONTACT_DIR / "contact_native_button_textures_2026_07_09.png")
    print(f"Generated {len(written)} native button textures")
    print(CONTACT_DIR / "contact_native_button_textures_2026_07_09.png")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
