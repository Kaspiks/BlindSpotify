import { Controller } from "@hotwired/stimulus"
import { playbackLog } from "playback/playback_logger"

const LS_MODE = "blindjam_playback_mode"
const LS_PROVIDER = "blindjam_external_provider"
const PLAYBACK_MODE_PREVIEW = "preview"
const PLAYBACK_MODE_EXTERNAL = "external"

// Persists playback mode + provider scaffold (Spotify today) in localStorage for the WebView.
export default class extends Controller {
  static targets = ["modePreview", "modeExternal", "providerSpotify"]

  connect() {
    this.syncFromStorage()
  }

  syncFromStorage() {
    let mode = PLAYBACK_MODE_PREVIEW
    let provider = "spotify"
    try {
      mode = localStorage.getItem(LS_MODE) === PLAYBACK_MODE_EXTERNAL ? PLAYBACK_MODE_EXTERNAL : PLAYBACK_MODE_PREVIEW
      provider = localStorage.getItem(LS_PROVIDER) || "spotify"
    } catch (_) { /* private mode */ }

    if (this.hasModePreviewTarget) this.modePreviewTarget.checked = mode === PLAYBACK_MODE_PREVIEW
    if (this.hasModeExternalTarget) this.modeExternalTarget.checked = mode === PLAYBACK_MODE_EXTERNAL
    if (this.hasProviderSpotifyTarget) this.providerSpotifyTarget.checked = provider === "spotify"

    playbackLog("info", "playback_settings_loaded", { mode, provider })
  }

  setModePreview() {
    this._saveMode(PLAYBACK_MODE_PREVIEW)
  }

  setModeExternal() {
    this._saveMode(PLAYBACK_MODE_EXTERNAL)
  }

  setProviderSpotify() {
    try {
      localStorage.setItem(LS_PROVIDER, "spotify")
      playbackLog("info", "playback_provider_saved", { provider: "spotify" })
    } catch (e) {
      playbackLog("warn", "playback_provider_save_failed", { message: e?.message })
    }
  }

  _saveMode(mode) {
    try {
      localStorage.setItem(LS_MODE, mode)
      playbackLog("info", "playback_mode_saved", { mode })
    } catch (e) {
      playbackLog("warn", "playback_mode_save_failed", { message: e?.message })
    }
  }
}
