#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / "assets/production/fonts/font_main.ttf"
LICENSE = ROOT / "assets/production/fonts/OFL-GlowSans.txt"
PROVENANCE = ROOT / "assets/production/fonts/font_main.provenance.json"
EXPECTED_SHA256 = "56481618894253fb71427a097706f9a440806b4957a7381946dc6464b98aa192"
EXPECTED_BYTES = 9_176_176


def main() -> int:
    errors: list[str] = []
    if not FONT.is_file():
        errors.append(f"missing runtime font: {FONT.relative_to(ROOT)}")
    else:
        data = FONT.read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        if digest != EXPECTED_SHA256:
            errors.append(f"runtime font hash mismatch: {digest}")
        if len(data) != EXPECTED_BYTES:
            errors.append(f"runtime font size mismatch: {len(data)}")
        if data[:4] != b"OTTO":
            errors.append("runtime font is not the official OpenType/CFF release binary")

    if not LICENSE.is_file():
        errors.append(f"missing font license: {LICENSE.relative_to(ROOT)}")
    else:
        license_text = LICENSE.read_text(encoding="utf-8")
        for required in [
            "Copyright (c) 2020, Celestial Phineas",
            "SIL OPEN FONT LICENSE Version 1.1",
            "The OFL allows the licensed fonts to be used, studied, modified and",
        ]:
            if required not in license_text:
                errors.append(f"font license is missing required text: {required}")

    if not PROVENANCE.is_file():
        errors.append(f"missing font provenance: {PROVENANCE.relative_to(ROOT)}")
    else:
        try:
            provenance = json.loads(PROVENANCE.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"invalid font provenance JSON: {exc}")
        else:
            expected = {
                "asset": "assets/production/fonts/font_main.ttf",
                "family": "Glow Sans SC / 未来荧黑",
                "style": "Normal Medium",
                "release": "v0.93",
                "shipped_sha256": EXPECTED_SHA256,
                "shipped_bytes": EXPECTED_BYTES,
                "binary_unchanged": True,
                "license": "SIL Open Font License 1.1",
                "license_file": "assets/production/fonts/OFL-GlowSans.txt",
            }
            for key, value in expected.items():
                if provenance.get(key) != value:
                    errors.append(f"font provenance mismatch for {key}: {provenance.get(key)!r}")

    if errors:
        print("Font license check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Font license check passed: Glow Sans SC Normal Medium v0.93 / SIL OFL 1.1")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
