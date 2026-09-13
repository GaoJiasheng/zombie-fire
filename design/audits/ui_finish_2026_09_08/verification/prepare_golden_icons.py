#!/usr/bin/env python3
"""Owner-approved deterministic finish of reviewed built-in imagegen outputs.

No asset generation, model download, gameplay image or geometry edits. Stages
RGBA icons only; runtime promotion is a separate, explicitly reviewed step.
"""
import hashlib
import json
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from rembg import new_session, remove

ROOT = Path(__file__).resolve().parents[4]
PROD = ROOT / 'assets/production'
STAGE = PROD / 'source_refs/generated/ui_finish_2026_09_08'
GENERATED = Path('/Users/gavin/.codex/generated_images/01a04d2c-37f4-7090-bd0a-90594728e586')
INPUTS = {
    'chip_apocalypse_golden_law_icon': 'exec-fdba3ddc-9fcb-4471-acc1-284529290e2d.png',
    'pet_apocalypse_skyfalcon_icon': 'exec-81f26810-1e45-4b98-bc7e-56aed8f540ea.png',
}

def native_icon(image):
    image = image.convert('RGBA')
    bounds = image.getchannel('A').point(lambda a: 255 if a >= 8 else 0).getbbox()
    assert bounds
    subject = image.crop(bounds)
    subject.thumbnail((336, 336), Image.Resampling.LANCZOS)
    icon = Image.new('RGBA', (384, 384))
    icon.alpha_composite(subject, ((384-subject.width)//2, (384-subject.height)//2))
    return icon

def main():
    STAGE.mkdir(parents=True, exist_ok=True)
    assert Path('/Users/gavin/.u2net/u2net.onnx').is_file(), 'Only the cached local extraction model is authorized'
    session = new_session('u2net', providers=['CPUExecutionProvider'])
    manifest = {}
    previews = Image.new('RGB', (768, 768))
    for index, (name, filename) in enumerate(INPUTS.items()):
        original = GENERATED / filename
        source = STAGE / (name + '_imagegen_source.png')
        if not source.exists():
            shutil.copy2(original, source)
        image = Image.open(source)
        if name.startswith('pet_'):
            image = remove(image, session=session, alpha_matting=True,
                           alpha_matting_foreground_threshold=235,
                           alpha_matting_background_threshold=15,
                           alpha_matting_erode_size=5)
            # The extractor mistakes checkerboard enclosed by the trailing
            # golden filaments for foreground. Remove only neutral backdrop
            # in that reviewed open-air region; the metal body is excluded.
            region = Image.new('L', image.size)
            w, h = image.size
            ImageDraw.Draw(region).polygon([(int(x*w), int(y*h)) for x,y in
                [(0.93,0.30),(1.0,0.30),(1.0,0.70),(0.61,0.61),(0.66,0.45)]], fill=255)
            pixels = np.asarray(image.convert('RGBA')).copy()
            rgb = pixels[:,:,:3].astype(float)
            chroma = rgb.max(axis=2)-rgb.min(axis=2)
            backdrop = (np.asarray(region)>0) & (rgb.min(axis=2)>150)
            clean_alpha = np.clip((chroma-10)/24, 0, 1)*255
            pixels[:,:,3][backdrop] = np.minimum(pixels[:,:,3][backdrop], clean_alpha[backdrop]).astype('uint8')
            image = Image.fromarray(pixels)
        image = image.convert('RGBA')
        image.save(STAGE / (name + '_rgba_master.png'))
        icon = native_icon(image)
        target = STAGE / (name + '.png')
        icon.save(target)
        alpha = np.asarray(icon)[:, :, 3]
        assert alpha[0].max() == 0 and alpha[-1].max() == 0
        assert alpha[:,0].max() == 0 and alpha[:,-1].max() == 0
        manifest[name] = dict(source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                              native_sha256=hashlib.sha256(target.read_bytes()).hexdigest(),
                              size=list(icon.size), mode=icon.mode,
                              alpha_bbox=list(icon.getchannel('A').getbbox()),
                              fully_transparent_pixels=int((alpha == 0).sum()))
        for row, background in enumerate(['#101923', '#e2e6e9']):
            sample = Image.new('RGBA', icon.size, background)
            sample.alpha_composite(icon)
            previews.paste(sample.convert('RGB'), (index*384, row*384))
    previews.save(STAGE / 'native_dark_light_review.png')
    (STAGE / 'processing_manifest.json').write_text(json.dumps(manifest, indent=2))
    print(json.dumps(manifest, indent=2))

if __name__ == '__main__':
    main()
