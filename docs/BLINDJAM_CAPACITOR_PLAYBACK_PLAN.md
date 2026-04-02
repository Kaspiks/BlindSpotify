# BlindJam — Capacitor shell & playback architecture (implementation plan)

## Phase 1 — Analysis (completed)

### Project shape

- **Rails 8 + Hotwire**: Player UI in Slim, Stimulus controllers, Turbo streams for games.
- **`mobile/`** already contains Capacitor 7 + Android; Makefile syncs `server.url` from `CAPACITOR_SERVER_URL` (emulator default `http://10.0.2.2:3024`).
- **Game loop**: `games#show` renders `_track_card` with optional `audio-player` + preview URL refresh.
- **Tracks**: Deezer-backed `preview_url` (+ iTunes fallback); QR flow at `/q/:token`.

### webDir vs live server

| Environment | Recommendation |
|-------------|------------------|
| **Development** | **Live server URL** baked at `cap sync`: same cookies, Cable, Turbo as desktop; no duplicate asset pipeline. |
| **Production** | **HTTPS `server.url`** to your deployed origin (or future static `webDir` export only if you intentionally ship offline shell — not required here). |
| **`mobile/www/`** | Keep minimal fallback when `CAPACITOR_SERVER_URL` is unset (already in `capacitor.config.js`). |

### Simplest architecture

- **Single source of truth**: Rails for routes, auth, game state, track metadata JSON.
- **Capacitor**: WebView + `@capacitor/app` lifecycle (resume/pause) for external Spotify handoff.
- **Frontend**: Small **playback coordinator + adapters** under `app/javascript/playback/`, one Stimulus `playback-host` for UX (loading, transition, resume banner, debounce).

## Implementation phases (execution order)

1. **Data**: Optional `tracks.spotify_uri`, `tracks.external_web_url`; JSON `GET /q/:token/playback` for resolver clients.
2. **JS core**: `PlaybackCoordinator` + `PreviewPlaybackAdapter`, `SpotifyExternalAdapter`, `NullPlaybackAdapter`; `playbackLogger`.
3. **Stimulus**: `playback-host` — wires coordinator, Capacitor `App` plugin when `window.Capacitor.Plugins.App` exists, `visibilitychange` fallback in browser; `sessionStorage` handoff; debounced external launch.
4. **UI**: Game `_track_card` + optional `tracks/play` + `_playback_settings` (localStorage: mode + provider).
5. **Mobile**: Align Capacitor `appId` / Android `applicationId` with **BlindJam**; keep cleartext only for dev HTTP as today.
6. **Polish**: Locales, error states, logging prefixes `[BlindJam:Playback]`.

## Extensibility

- New providers: implement adapter with `openExternal(track)` + URL builders; register in coordinator factory.
- iOS later: same JS; verify `spotify:` / universal links and `App.addListener('resume')`.

## Risks / limitations

- **Cannot** force Spotify to background or guarantee track match (search URI vs exact track).
- **WebView** may handle custom schemes differently; fallback to `https://open.spotify.com/...` is required.
- **Resume** means “user returned to BlindJam”; game timing while away is not wall-clock authoritative unless server adds it later.
