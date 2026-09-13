#!/usr/bin/env python3
"""Read-only source screenshots, compose review thumbnails; never alter assets."""
import argparse
import html
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

AUDIT = Path(__file__).resolve().parents[1]
SHOTS = AUDIT / 'final02/screenshots/after'
STORE_SHOTS = AUDIT / 'supplement01/screenshots/after'
OUT = AUDIT / 'review'
THEMES = ['default', 'neon_tempest', 'infernal_dominion', 'polar_aurora', 'gilded_eclipse']
STATES = ['menu', 'map', 'map_chapter', 'loadout', 'collection_weapons', 'collection_characters', 'collection_skills', 'collection_armors', 'collection_chips', 'collection_pets', 'settings', 'store', 'pause', 'result', 'battle_hud', 'card_offer', 'theme_appearance']

def sources(labels):
    return [(STORE_SHOTS if (STORE_SHOTS / (label + '.png')).exists() else SHOTS) / (label + '.png') for label in labels]

def source_hashes(paths):
    return [json.loads(p.with_suffix('.json').read_text())['sha256'] for p in paths]

def needs_sheet(name, labels):
    metadata = OUT / (name + '.json')
    paths = sources(labels)
    if not all(p.exists() and p.with_suffix('.json').exists() for p in paths):
        return False
    if not metadata.exists() or not (OUT / (name + '.jpg')).exists():
        return True
    old = json.loads(metadata.read_text())
    return old.get('full_size_sources') != [str(p.relative_to(AUDIT)) for p in paths] or old.get('source_sha256') != source_hashes(paths)

def sheet(name, labels, columns=3, width=360):
    paths = sources(labels)
    if not all(p.exists() for p in paths):
        return False
    font = ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', 13)
    thumbs = []
    for path in paths:
        with Image.open(path) as src:
            thumb = src.convert('RGB')
            thumb.thumbnail((width, 800), Image.Resampling.LANCZOS)
        thumbs.append(thumb)
    cell_h = max(im.height for im in thumbs) + 66
    canvas = Image.new('RGB', (columns * (width + 16) + 16, math.ceil(len(labels) / columns) * cell_h + 16), '#18232d')
    draw = ImageDraw.Draw(canvas)
    for i, (label, thumb) in enumerate(zip(labels, thumbs)):
        x, y = 16 + (i % columns) * (width + 16), 16 + (i // columns) * cell_h
        for j in range(0, min(len(label), 120), 43):
            draw.text((x, y + 15 * (j // 43)), label[j:j+43], fill='#e7edf0', font=font)
        canvas.paste(thumb, (x + (width - thumb.width) // 2, y + 50))
    OUT.mkdir(exist_ok=True)
    canvas.save(OUT / (name + '.jpg'), quality=92)
    (OUT / (name + '.json')).write_text(json.dumps(dict(labels=labels, full_size_sources=[str(p.relative_to(AUDIT)) for p in paths], source_sha256=source_hashes(paths)), indent=2))
    return True

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--all-ready', action='store_true')
    args = parser.parse_args()
    count = 0
    for size in ['1080x1920', '1320x2868', '750x1334']:
        for lang in ['zh', 'en']:
            for hero in ['vanguard', 'blaze', 'frost', 'volt']:
                labels = [f'owned_character_{theme}_{hero}_{lang}_{size}' for theme in THEMES]
                name = f'character_{hero}_{size}_{lang}'
                if needs_sheet(name, labels):
                    count += sheet(name, labels)
            for state in STATES:
                labels = [f'core_{size}_{lang}_{theme}_{state}' for theme in THEMES]
                name = f'{size}_{lang}_{state}'
                if needs_sheet(name, labels):
                    count += sheet(name, labels)
    groups = []
    for path in sorted(OUT.glob('*.jpg')):
        caption = html.escape(path.stem)
        groups.append(f'<li><a href="review/{path.name}" target="_blank">{caption}</a></li>')
    if groups:
        (AUDIT / '同屏对照索引.html').write_text('<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>五主题同屏对照</title><style>body{max-width:1000px;margin:32px auto;padding:0 18px;font:17px/1.8 system-ui;background:#15202a;color:#e8edef;overflow-wrap:anywhere}a{color:#8ed4e1}li{margin:6px 0}</style><h1>五主题同屏对照</h1><p>顺序：默认、霓虹、炼狱、极光、黄金。缩略图用于检查一致性，文字是否完整请回到原生截图查看；不要把缩略图当作实际字号。</p><ul>' + ''.join(groups) + '</ul></html>')
    print(f'Created {count} complete five-theme review sheets; {len(groups)} available; incomplete groups wait for capture.')

if __name__ == '__main__':
    main()
