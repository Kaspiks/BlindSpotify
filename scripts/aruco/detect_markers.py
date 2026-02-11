#!/usr/bin/env python3
"""
Detect ArUco marker IDs in an image. Used by the Rails deck-scan endpoint.

Reads image path from argv, prints one marker ID per line to stdout (unsorted).
Uses the same dictionary as generate_markers.py (DICT_4X4_250).

Usage:
  python scripts/aruco/detect_markers.py /path/to/image.png
"""
from __future__ import annotations

import sys

try:
    import cv2
    from cv2 import aruco
except ImportError:
    print("Install OpenCV with contrib: pip install opencv-python opencv-contrib-python", file=sys.stderr)
    sys.exit(2)

ARUCO_DICT = aruco.getPredefinedDictionary(aruco.DICT_4X4_250)
# Standard detector parameters (OpenCV 4.7+ uses DetectorParameters(), older uses DetectorParameters_create())
try:
    DETECTOR_PARAMS = aruco.DetectorParameters()
except AttributeError:
    DETECTOR_PARAMS = aruco.DetectorParameters_create()


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: detect_markers.py <image_path>", file=sys.stderr)
        sys.exit(1)

    path = sys.argv[1]
    img = cv2.imread(path)
    if img is None:
        print(f"Could not read image: {path}", file=sys.stderr)
        sys.exit(3)

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    # OpenCV 4.7+: ArucoDetector; older: detectMarkers with DetectorParameters
    try:
        detector = aruco.ArucoDetector(ARUCO_DICT, DETECTOR_PARAMS)
        corners, ids, _ = detector.detectMarkers(gray)
    except (AttributeError, TypeError):
        params = getattr(aruco, "DetectorParameters_create", lambda: aruco.DetectorParameters())()
        corners, ids, _ = aruco.detectMarkers(gray, ARUCO_DICT, parameters=params)

    if ids is None or len(ids) == 0:
        sys.exit(0)

    # ids is (N, 1) array of integers
    seen = set()
    for i in range(ids.shape[0]):
        mid = int(ids[i, 0])
        if mid not in seen:
            seen.add(mid)
            print(mid)

    sys.exit(0)


if __name__ == "__main__":
    main()
