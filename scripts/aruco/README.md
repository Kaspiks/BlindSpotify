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

### Production (e.g. Render)

Deck scan (ArUco detection) runs **server-side** and needs **Python 3** and **OpenCV with contrib** (`opencv-python`, `opencv-contrib-python`). If these are missing, scans always return "No cards detected."

- **Render with Docker:** Use the project’s **Dockerfile** as the Render service image. It already installs Python and the `scripts/aruco/requirements.txt` dependencies. Deploy as a "Docker" web service, not the Ruby buildpack.
- **Render with Ruby buildpack:** The buildpack does not install Python/OpenCV. Either switch to Docker deploy, or add a custom build step that installs Python 3 and runs `pip install -r scripts/aruco/requirements.txt` (non-trivial on the Ruby runtime).
- **Logs:** If detection fails, the app logs `[DeckScan] ArUco script failed` and the script’s stderr (e.g. "python3: command not found" or "No module named 'cv2'") so you can confirm the cause in your host’s logs.
