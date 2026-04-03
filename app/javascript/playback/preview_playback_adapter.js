import { playbackLog } from "playback/playback_logger"

// In-app HTMLAudio preview using track.preview_url (short clip).
export class PreviewPlaybackAdapter {
  constructor(getAudioElement) {
    this.getAudioElement = getAudioElement
    this._handlers = { start: [], end: [], error: [] }
    this._onEnded = this._onEnded.bind(this)
    this._onError = this._onError.bind(this)
    this._onPlaying = this._onPlaying.bind(this)
  }

  on(event, cb) {
    if (!this._handlers[event]) this._handlers[event] = []
    this._handlers[event].push(cb)
  }

  _emit(event, payload) {
    for (const cb of this._handlers[event] || []) {
      try {
        cb(payload)
      } catch (e) {
        playbackLog("error", "preview_adapter_listener_error", { message: e?.message })
      }
    }
  }

  _bindAudio(audio) {
    audio.removeEventListener("ended", this._onEnded)
    audio.removeEventListener("error", this._onError)
    audio.removeEventListener("playing", this._onPlaying)
    audio.addEventListener("ended", this._onEnded)
    audio.addEventListener("error", this._onError)
    audio.addEventListener("playing", this._onPlaying, { once: true })
  }

  _onPlaying() {
    playbackLog("info", "preview_started", {})
    this._emit("start", {})
  }

  _onEnded() {
    playbackLog("info", "preview_ended", {})
    this._emit("end", {})
  }

  _onError(e) {
    playbackLog("error", "preview_error", { message: e?.message || "audio_error" })
    this._emit("error", { code: "playback_error" })
  }

  async playPreview(track) {
    const audio = typeof this.getAudioElement === "function" ? this.getAudioElement() : null
    if (!audio) {
      playbackLog("warn", "preview_no_audio_element", { token: track?.token })
      this._emit("error", { code: "no_audio_element" })
      return false
    }

    const url = track.preview_url
    if (!url) {
      this._emit("error", { code: "no_preview_url" })
      return false
    }

    this._bindAudio(audio)
    audio.removeAttribute("crossorigin")
    audio.src = url
    audio.load()

    try {
      await audio.play()
      return true
    } catch (e) {
      playbackLog("error", "preview_play_rejected", { message: e?.message })
      this._emit("error", { code: "play_rejected" })
      return false
    }
  }

  stop() {
    const audio = this.getAudioElement?.()
    if (!audio) return
    audio.pause()
    audio.currentTime = 0
  }
}
