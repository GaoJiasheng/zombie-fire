#!/usr/bin/env python3
from __future__ import annotations

"""Compatibility wrapper for the accepted image-generated main title pass.

The owner rejected the older font-effect title renders. Keep this filename as a
stable entrypoint, but route it to the imagegen-source processor so running old
handoff commands cannot overwrite the accepted title with local font art.
"""

from process_menu_title_imagegen_2026_07_10 import main


if __name__ == "__main__":
	main()
