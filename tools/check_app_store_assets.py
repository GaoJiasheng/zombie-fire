#!/usr/bin/env python3
from __future__ import annotations

import configparser
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

    required_dirs = {
        "ios_67": (1290, 2796),
        "ios_65": (1242, 2688),
        "ipad_129": (2048, 2732),
    }
    for folder, size in required_dirs.items():
        files = sorted((ROOT / "assets/appstore/screenshots" / folder).glob("*.png"))
        if len(files) < 3:
            errors.append(f"{folder} needs at least 3 screenshot drafts")
        for file in files:
            if image_size(file) != size:
                errors.append(f"{file.relative_to(ROOT)} must be {size}, got {image_size(file)}")

    for page in ["docs/public/privacy.html", "docs/public/support.html"]:
        if not (ROOT / page).exists():
            errors.append(f"missing public page draft: {page}")

    if not (ROOT / "ios/PrivacyInfo.xcprivacy").exists():
        errors.append("missing iOS privacy manifest draft")

    if not (ROOT / "export_presets.cfg").exists():
        errors.append("missing Godot export presets")
    else:
        parser = configparser.ConfigParser()
        parser.read(ROOT / "export_presets.cfg")
        text = (ROOT / "export_presets.cfg").read_text()
        if "iOS Release Candidate" not in text:
            errors.append("export presets missing iOS release candidate")
        if "macOS Release Candidate" not in text:
            errors.append("export presets missing macOS release candidate")

    if errors:
        print("App Store asset check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("App Store asset check OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
