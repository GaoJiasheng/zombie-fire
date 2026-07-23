#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
from itertools import combinations
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def image_size(path: Path) -> tuple[int, int]:
    with Image.open(path) as image:
        return image.size


def main() -> int:
    errors: list[str] = []
    icon = ROOT / "assets/app/app_icon_1024.png"
    if not icon.exists():
        errors.append("missing app icon")
    else:
        with Image.open(icon) as image:
            if image.size != (1024, 1024):
                errors.append(f"app icon must be 1024x1024, got {image.size}")
            if image.mode in {"RGBA", "LA"}:
                errors.append("app icon must not contain alpha")

    # The current store target is iPhone-only. Keep both current iPhone sizes
    # fresh so marketing captures and device QA cover standard and tall phones.
    required_dirs = {
        "ios_67": (1290, 2796),
        "ios_65": (1242, 2688),
    }
    for folder, size in required_dirs.items():
        files = sorted((ROOT / "assets/appstore/screenshots" / folder).glob("*.png"))
        expected_names = ["01_battle.png", "02_map.png", "03_skills.png", "04_loadout.png", "05_boss.png"]
        if [file.name for file in files] != expected_names:
            errors.append(f"{folder} must contain the five ordered launch screenshots: {expected_names}")
        fingerprints: dict[str, list[int]] = {}
        for file in files:
            with Image.open(file) as image:
                if image.size != size:
                    errors.append(f"{file.relative_to(ROOT)} must be {size}, got {image.size}")
                if image.mode not in {"RGB", "L"}:
                    errors.append(f"{file.relative_to(ROOT)} must not contain alpha, got {image.mode}")
                fingerprints[file.name] = list(image.convert("L").resize((24, 24)).getdata())
        for left, right in combinations(fingerprints, 2):
            delta = sum(abs(a - b) for a, b in zip(fingerprints[left], fingerprints[right])) / 576.0
            if delta < 1.0:
                errors.append(f"{folder} screenshots are visually duplicated: {left} / {right}")

    preview = ROOT / "assets/production/video/vid_app_preview.mp4"
    provenance_path = ROOT / "assets/production/video/vid_app_preview_provenance.json"
    ffprobe = shutil.which("ffprobe")
    if not preview.is_file() or not provenance_path.is_file():
        errors.append("missing App Preview movie or runtime provenance")
    elif ffprobe is None:
        errors.append("ffprobe is required for App Preview validation")
    else:
        probe = json.loads(subprocess.check_output(
            [ffprobe, "-v", "error", "-show_streams", "-show_format", "-of", "json", str(preview)],
            text=True,
        ))
        videos = [stream for stream in probe.get("streams", []) if stream.get("codec_type") == "video"]
        audios = [stream for stream in probe.get("streams", []) if stream.get("codec_type") == "audio"]
        if len(videos) != 1 or len(audios) != 1:
            errors.append("App Preview must contain exactly one video and one audio stream")
        else:
            video, audio = videos[0], audios[0]
            if (video.get("codec_name"), int(video.get("width", 0)), int(video.get("height", 0))) != ("h264", 886, 1920):
                errors.append("App Preview must be H.264 at 886x1920")
            if str(video.get("sample_aspect_ratio", "")) not in {"1:1", "N/A"}:
                errors.append(f"App Preview must use square pixels, got SAR={video.get('sample_aspect_ratio')}")
            fps_num, fps_den = (int(value) for value in str(video.get("r_frame_rate", "0/1")).split("/"))
            fps = fps_num / max(fps_den, 1)
            if not 23.0 <= fps <= 30.0:
                errors.append(f"App Preview frame rate must be 23-30 fps, got {fps:.2f}")
            if int(video.get("bit_rate", 0)) < 8_000_000:
                errors.append("App Preview video bitrate must be at least 8 Mbps")
            if audio.get("codec_name") != "aac" or int(audio.get("channels", 0)) != 2:
                errors.append("App Preview audio must be stereo AAC")
            if int(audio.get("bit_rate", 0)) < 192_000:
                errors.append("App Preview audio bitrate must be at least 192 kbps")
        duration = float(probe.get("format", {}).get("duration", 0.0))
        if not 15.0 <= duration <= 30.0:
            errors.append(f"App Preview duration must be 15-30 seconds, got {duration:.2f}")
        provenance = json.loads(provenance_path.read_text(encoding="utf-8"))
        if provenance.get("capture_type") != "godot_runtime_movie":
            errors.append("App Preview must come from a live Godot runtime capture")
        if provenance.get("capture_resolution") != "1080x2340" or provenance.get("sample_aspect_ratio") != "1:1":
            errors.append("App Preview provenance must record the tall square-pixel capture pipeline")
        capture_script = ROOT / str(provenance.get("capture_script", "")).removeprefix("res://")
        if not capture_script.is_file():
            errors.append("App Preview provenance points to a missing capture script")
        digest = hashlib.sha256(preview.read_bytes()).hexdigest()
        if provenance.get("sha256") != digest:
            errors.append("App Preview provenance hash is stale")

    for page in ["docs/public/privacy.html", "docs/public/support.html"]:
        if not (ROOT / page).exists():
            errors.append(f"missing public page draft: {page}")

    if not (ROOT / "ios/PrivacyInfo.xcprivacy").exists():
        errors.append("missing iOS privacy manifest draft")

    if not (ROOT / "export_presets.cfg").exists():
        errors.append("missing Godot export presets")
    else:
        text = (ROOT / "export_presets.cfg").read_text()
        if "iOS Release Candidate" not in text:
            errors.append("export presets missing iOS release candidate")
        if "macOS Release Candidate" not in text:
            errors.append("export presets missing macOS release candidate")
        if "application/targeted_device_family=0" not in text:
            errors.append("iOS release candidate must target iPhone only")

    project_text = (ROOT / "project.godot").read_text()
    if 'window/stretch/mode="canvas_items"' not in project_text:
        errors.append("project stretch mode must remain canvas_items")
    if 'window/stretch/aspect="expand"' not in project_text:
        errors.append("project stretch aspect must remain expand for tall iPhones")

    if errors:
        print("App Store asset check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("App Store asset check OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
