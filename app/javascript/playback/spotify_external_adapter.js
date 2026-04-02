import { playbackLog } from "playback/playback_logger"

export const SPOTIFY_HANDOFF_STORAGE_KEY = "blindjam_external_handoff_v1"

// Opens Spotify (app via custom scheme on native, or web) and persists handoff for resume UX.
export class SpotifyExternalAdapter {
  persistHandoff(payload) {
    try {
      sessionStorage.setItem(SPOTIFY_HANDOFF_STORAGE_KEY, JSON.stringify({ v: 1, ts: Date.now(), ...payload }))
      playbackLog("info", "external_handoff_saved", { token: payload.token, gameId: payload.gameId })
    } catch (e) {
      playbackLog("warn", "external_handoff_save_failed", { message: e?.message })
    }
  }

  readHandoff() {
    try {
      const raw = sessionStorage.getItem(SPOTIFY_HANDOFF_STORAGE_KEY)
      return raw ? JSON.parse(raw) : null
    } catch {
      return null
    }
  }

  clearHandoff() {
    try {
      sessionStorage.removeItem(SPOTIFY_HANDOFF_STORAGE_KEY)
    } catch (_) { /* ignore */ }
  }

  openExternal(track, context) {
    const { gameId, path, launchId } = context
    this.persistHandoff({
      provider: "spotify",
      token: track.token,
      gameId,
      path: path || (typeof window !== "undefined" ? window.location.pathname : null),
      launchId,
      trackTitle: track.title,
      trackArtist: track.artist_name
    })

    const appUri = track.spotify_app_uri
    const webUrl = track.spotify_web_url
    const isNative = typeof window !== "undefined" && window.Capacitor?.isNativePlatform?.()

    playbackLog("info", "external_launch_attempt", {
      isNative,
      hasAppUri: !!appUri,
      webHost: webUrl ? new URL(webUrl).host : null,
      token: track.token,
      launchId
    })

    try {
      if (isNative && appUri) {
        // WebView delegates spotify: to the OS when the handler is registered.
        window.location.href = appUri
        playbackLog("info", "deep_link_navigate", { scheme: appUri.split(":")[0] })
      } else if (webUrl) {
        window.open(webUrl, "_blank", "noopener,noreferrer")
        playbackLog("info", "external_open_web_tab", { token: track.token })
      } else {
        playbackLog("error", "external_no_url", { token: track.token })
        return false
      }
      return true
    } catch (e) {
      playbackLog("error", "external_launch_exception", { message: e?.message })
      if (webUrl) {
        window.open(webUrl, "_blank", "noopener,noreferrer")
        return true
      }
      return false
    }
  }
}
