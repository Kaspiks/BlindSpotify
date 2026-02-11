# ArUco scripts for printable cards

- **generate_markers.py** – Pre-generate marker PNGs (IDs `0` … `N-1`) into `vendor/assets/aruco/`.  
  Run from repo root or pass `--out`:

  **Option A – inside app container (no local Python needed):**
  ```bash
  docker compose exec web bash
  python3 scripts/aruco/generate_markers.py --count 200
  ```
  (The app image includes Python 3 and OpenCV; output is written into the mounted app dir.)  
  If you see "Install OpenCV with contrib", rebuild the image so the pip step runs: `docker compose build --no-cache web`. Or install once in the running container: `docker compose exec -u root web pip3 install --no-cache-dir --break-system-packages -r /app/scripts/aruco/requirements.txt`

  **Option B – on your machine:**
  ```bash
  pip install -r scripts/aruco/requirements.txt
  python3 scripts/aruco/generate_markers.py --count 200
  ```

- **detect_markers.py** – Used by the Rails deck-scan endpoint. Reads an image path, prints detected marker IDs (one per line).  
  Same dictionary as generation (`DICT_4X4_250`).

On Hetzner (or any host with Python + OpenCV), the Rails app can call `detect_markers.py` when a user uploads a photo of their deck to resolve which cards are visible.
