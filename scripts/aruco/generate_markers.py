#!/usr/bin/env python3
"""
Generate ArUco marker PNGs for printable cards.

Marker ID = 0-based index (0, 1, 2, ...). The Rails app maps these to track
position in a playlist: track at position 1 uses marker 0, position 2 uses
marker 1, etc.

Usage:
  python scripts/aruco/generate_markers.py [--count N] [--size PX] [--out DIR]

Defaults: count=200, size=400, out=vendor/assets/aruco (from repo root).
"""
from __future__ import annotations

import argparse
import os
import sys

try:
    import cv2
    from cv2 import aruco
except ImportError:
    print("Install OpenCV with contrib: pip install opencv-python opencv-contrib-python", file=sys.stderr)
    sys.exit(1)

# Dictionary 4x4 with 250 markers (IDs 0..249). Good for playlists up to 250 tracks.
ARUCO_DICT = aruco.getPredefinedDictionary(aruco.DICT_4X4_250)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate ArUco marker images for card fronts.")
    parser.add_argument("--count", type=int, default=200, help="Number of markers to generate (IDs 0..count-1)")
    parser.add_argument("--size", type=int, default=400, help="Image size in pixels (square)")
    parser.add_argument("--out", type=str, default=None, help="Output directory (default: vendor/assets/aruco)")
    args = parser.parse_args()

    if args.out is None:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        repo_root = os.path.dirname(os.path.dirname(script_dir))
        args.out = os.path.join(repo_root, "vendor", "assets", "aruco")

    os.makedirs(args.out, exist_ok=True)
    size = args.size

    for marker_id in range(args.count):
        # OpenCV 4.7+: generateImageMarker; older: drawMarker
        try:
            img = aruco.generateImageMarker(ARUCO_DICT, marker_id, size)
        except AttributeError:
            img = aruco.drawMarker(ARUCO_DICT, marker_id, size)
        path = os.path.join(args.out, f"{marker_id}.png")
        cv2.imwrite(path, img)

    print(f"Generated {args.count} markers in {args.out}", file=sys.stderr)


if __name__ == "__main__":
    main()
