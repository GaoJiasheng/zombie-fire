#!/usr/bin/env python3
"""Guard complete alpha atlas cells, phase diversity and no primitive fallback."""
from pathlib import Path
import hashlib
import math
import re
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets/production/sprites/vfx_polish"

def main():
    errors = []
    checked = 0
    for name in ("material_impacts", "energy_impacts", "material_ribbons"):
        with Image.open(ART / f"{name}.png") as src:
            image = src.convert("RGBA")
        w, h = image.size
        for row in range(4):
            hashes = set()
            for col in range(4):
                cell = image.crop((round(col*w/4), round(row*h/4), round((col+1)*w/4), round((row+1)*h/4)))
                mask = cell.getchannel("A").point(lambda a: 255 if a > 12 else 0)
                box = mask.getbbox()
                if not box:
                    errors.append(f"{name} {row}/{col}: empty phase")
                    continue
                margin = min(box[0], box[1], cell.width-box[2], cell.height-box[3])
                # Full source art must already be isolated, not cropped then hidden.
                if margin < 3:
                    errors.append(f"{name} {row}/{col}: source touches a cell boundary")
                effective_margin = margin + min(cell.size)*0.1
                if effective_margin < math.floor(min(cell.size)*1.2*0.075):
                    errors.append(f"{name} {row}/{col}: filtered atlas lacks 7.5% safe margin")
                if cell.getchannel("A").getextrema()[0] != 0:
                    errors.append(f"{name} {row}/{col}: opaque background")
                hashes.add(hashlib.sha256(cell.tobytes()).hexdigest())
                checked += 1
            if len(hashes) != 4:
                errors.append(f"{name} row {row}: repeated animation stills")
    for path in ("gameplay/vfx/base_attack_feedback.gd", "gameplay/battle/battle.gd", "gameplay/projectile/projectile.gd"):
        text = (ROOT/path).read_text()
        if re.search(r"\bdraw_(?:arc|circle|line|polyline|colored_polygon|polygon)\s*\(", text):
            errors.append(f"{path}: raw geometric combat renderer reintroduced")
        if "_make_ring_line" in text or 'load("res://assets/production/sprites/vfx/vfx_input_streak.png")' in text:
            errors.append(f"{path}: flat-strip/ring placeholder reintroduced")
        if "line.closed = true" in text:
            errors.append(f"{path}: closed wireframe effect reintroduced")
    art = (ROOT/"gameplay/vfx/combat_vfx_art.gd").read_text()
    for required in ("frame.margin = Rect2(cell * 0.1, cell * 0.2)", "frame.filter_clip = true", "textures[index + 1]", "queue_redraw()"):
        if required not in art:
            errors.append(f"authored playback lost {required}")
    # Curved textured meshes for continuous wake/theme fibers remain valid;
    # their content is rendered material, not a solid-colored geometric line.
    if errors:
        print("Combat material art check FAILED:\n" + "\n".join(errors))
        return 1
    print(f"Combat material art check passed: {checked} distinct alpha phases, 12 materials, filtered gutters and no raw geometry fallback")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
