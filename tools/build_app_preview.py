#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/production/video/vid_app_preview.mp4"
PROVENANCE = ROOT / "assets/production/video/vid_app_preview_provenance.json"
CAPTURE_SCRIPT = "res://tools/_app_preview_capture.gd"
FPS = 24
DURATION = 22.0
SIZE = "886x1920"
CAPTURE_SIZE = "1080x2340"


def _tool(name: str, fallback: str | None = None) -> str:
    found = shutil.which(name)
    if found:
        return found
    if fallback and Path(fallback).is_file():
        return fallback
    raise RuntimeError(f"required tool not found: {name}")


def _capture_project(temp_root: Path) -> Path:
    project = temp_root / "capture_project"
    project.mkdir()
    for child in ROOT.iterdir():
        if child.name in {".git", "build", "tmp", "project.godot"}:
            continue
        os.symlink(child, project / child.name, target_is_directory=child.is_dir())
    project_text = (ROOT / "project.godot").read_text(encoding="utf-8")
    source = "window/size/viewport_height=1920"
    target = "window/size/viewport_height=2340"
    if project_text.count(source) != 1:
        raise RuntimeError("project viewport-height contract changed; refusing to build a distorted App Preview")
    (project / "project.godot").write_text(project_text.replace(source, target), encoding="utf-8")
    return project


def main() -> int:
    godot = _tool("godot", "/opt/homebrew/bin/godot")
    ffmpeg = _tool("ffmpeg")
    ffprobe = _tool("ffprobe")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="zombie_fire_runtime_preview_") as temp:
        temp_root = Path(temp)
        capture_project = _capture_project(temp_root)
        raw = temp_root / "runtime_capture.avi"
        subprocess.run(
            [
                godot, "--path", str(capture_project), "--display-driver", "macos",
                "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy",
                "--resolution", SIZE, "--fixed-fps", str(FPS),
                "--write-movie", str(raw), "--script", CAPTURE_SCRIPT,
            ],
            cwd=capture_project,
            check=True,
        )
        if not raw.is_file() or raw.stat().st_size < 1_000_000:
            raise RuntimeError("Godot runtime capture did not produce a valid movie")
        subprocess.run(
            [
                ffmpeg, "-y", "-i", str(raw), "-map", "0:v:0", "-map", "0:a:0",
                "-t", str(DURATION), "-vf", "scale=886:1920:flags=lanczos,setsar=1,format=yuv420p",
                "-r", str(FPS), "-c:v", "libx264", "-profile:v", "high", "-level:v", "4.1",
                # The live capture contains long, dark/static stretches. Plain ABR
                # can undershoot 10 Mbps by several times, which weakens gradients
                # and fails the launch quality gate. HRD CBR inserts legal filler
                # NAL units so even quiet scenes retain the requested data budget.
                "-b:v", "10M", "-minrate", "10M", "-maxrate", "10M", "-bufsize", "20M",
                "-x264-params", "nal-hrd=cbr:force-cfr=1", "-movflags", "+faststart",
                "-c:a", "aac", "-b:a", "256k", "-ac", "2", "-ar", "48000", "-shortest", str(OUTPUT),
            ],
            cwd=ROOT,
            check=True,
        )
    probe = json.loads(
        subprocess.check_output(
            [ffprobe, "-v", "error", "-show_streams", "-show_format", "-of", "json", str(OUTPUT)],
            text=True,
        )
    )
    video = next(stream for stream in probe["streams"] if stream["codec_type"] == "video")
    audio = next(stream for stream in probe["streams"] if stream["codec_type"] == "audio")
    if (video["codec_name"], int(video["width"]), int(video["height"])) != ("h264", 886, 1920):
        raise RuntimeError(f"unexpected preview video stream: {video}")
    if str(video.get("sample_aspect_ratio", "")) not in {"1:1", "N/A"}:
        raise RuntimeError(f"App Preview must use square pixels, got SAR={video.get('sample_aspect_ratio')}")
    if int(video.get("bit_rate", 0)) < 8_000_000:
        raise RuntimeError(f"App Preview bitrate undershot the quality floor: {video.get('bit_rate')}")
    if audio["codec_name"] != "aac" or int(audio.get("channels", 0)) != 2:
        raise RuntimeError(f"unexpected preview audio stream: {audio}")
    digest = hashlib.sha256(OUTPUT.read_bytes()).hexdigest()
    PROVENANCE.write_text(
        json.dumps(
            {
                "capture_type": "godot_runtime_movie",
                "capture_script": CAPTURE_SCRIPT,
                "source_level": "level_045",
                "duration_seconds": DURATION,
                "fps": FPS,
                "capture_resolution": CAPTURE_SIZE,
                "resolution": SIZE,
                "sample_aspect_ratio": "1:1",
                "video_codec": "h264",
                "audio_codec": "aac_stereo",
                "sha256": digest,
            },
            ensure_ascii=False,
            indent=2,
        ) + "\n",
        encoding="utf-8",
    )
    print(f"App Preview built from live Godot runtime: {OUTPUT.relative_to(ROOT)} ({OUTPUT.stat().st_size / 1024 / 1024:.1f} MiB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
