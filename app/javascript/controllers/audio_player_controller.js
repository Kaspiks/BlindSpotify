import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "playButton", "playIcon", "pauseIcon", "progress", "progressBar", "currentTime", "duration"]
  static values = { refreshUrl: String }

  connect() {
    this.isPlaying = false
    if (this.hasRefreshUrlValue && this.refreshUrlValue) {
      this.fetchPreviewUrlThenSetup()
    } else {
      this.setupAudio()
    }
  }

  async fetchPreviewUrlThenSetup() {
    try {
      const res = await fetch(this.refreshUrlValue, { headers: { Accept: "application/json" } })
      const data = await res.json()
      if (data.preview_url && this.hasAudioTarget) {
        const source = this.audioTarget.querySelector("source") || document.createElement("source")
        if (!this.audioTarget.querySelector("source")) {
          source.type = "audio/mpeg"
          this.audioTarget.appendChild(source)
        }
        source.src = data.preview_url
        this.audioTarget.load()
      }
    } catch (e) {
      console.warn("[AudioPlayer] Failed to refresh preview URL:", e)
    }
    this.setupAudio()
  }

  setupAudio() {
    if (!this.hasAudioTarget) {
      return
    }

    // Remove old listeners if any (for Turbo reconnection)
    this.audioTarget.removeEventListener("loadedmetadata", this.boundUpdateDuration)
    this.audioTarget.removeEventListener("timeupdate", this.boundUpdateProgress)
    this.audioTarget.removeEventListener("ended", this.boundOnEnded)
    this.audioTarget.removeEventListener("canplay", this.boundUpdateDuration)
    this.audioTarget.removeEventListener("error", this.boundOnError)

    // Create bound handlers
    this.boundUpdateDuration = () => this.updateDuration()
    this.boundUpdateProgress = () => this.updateProgress()
    this.boundOnEnded = () => this.onEnded()
    this.boundOnError = (e) => this.onError(e)

    // Add listeners
    this.audioTarget.addEventListener("loadedmetadata", this.boundUpdateDuration)
    this.audioTarget.addEventListener("timeupdate", this.boundUpdateProgress)
    this.audioTarget.addEventListener("ended", this.boundOnEnded)
    this.audioTarget.addEventListener("canplay", this.boundUpdateDuration)
    this.audioTarget.addEventListener("error", this.boundOnError)
    
    // Force load the audio
    this.audioTarget.load()
  }

  disconnect() {
    if (this.hasAudioTarget && !this.audioTarget.paused) {
      this.audioTarget.pause()
    }
  }

  toggle(event) {
    event.preventDefault()
    if (!this.hasAudioTarget) return

    if (this.isPlaying) {
      this.pause()
    } else {
      this.play()
    }
  }

  play() {
    if (!this.hasAudioTarget) {
      console.warn("[AudioPlayer] No audio target, cannot play")
      return
    }
    
    const playPromise = this.audioTarget.play()
    
    if (playPromise !== undefined) {
      playPromise
        .then(() => {
          this.isPlaying = true
          this.updateButtonState()
        })
        .catch((error) => {
          console.error("[AudioPlayer] Audio playback failed:", error)
          this.isPlaying = false
          this.updateButtonState()
        })
    } else {
      this.isPlaying = true
      this.updateButtonState()
    }
  }

  pause() {
    if (!this.hasAudioTarget) return
    
    this.audioTarget.pause()
    this.isPlaying = false
    this.updateButtonState()
  }

  seek(event) {
    if (!this.hasAudioTarget || !this.hasProgressBarTarget) return

    const rect = this.progressBarTarget.getBoundingClientRect()
    const percent = Math.max(0, Math.min(1, (event.clientX - rect.left) / rect.width))
    
    if (this.audioTarget.duration && isFinite(this.audioTarget.duration)) {
      this.audioTarget.currentTime = percent * this.audioTarget.duration
    }
  }

  updateButtonState() {
    if (this.hasPlayIconTarget && this.hasPauseIconTarget) {
      if (this.isPlaying) {
        this.playIconTarget.classList.add("hidden")
        this.pauseIconTarget.classList.remove("hidden")
      } else {
        this.playIconTarget.classList.remove("hidden")
        this.pauseIconTarget.classList.add("hidden")
      }
    }
  }

  updateProgress() {
    if (!this.hasAudioTarget) return

    const { currentTime, duration } = this.audioTarget
    
    if (duration && isFinite(duration) && this.hasProgressTarget) {
      const percent = (currentTime / duration) * 100
      this.progressTarget.style.width = `${percent}%`
    }

    if (this.hasCurrentTimeTarget) {
      this.currentTimeTarget.textContent = this.formatTime(currentTime)
    }
  }

  updateDuration() {
    if (!this.hasAudioTarget || !this.hasDurationTarget) return

    const { duration } = this.audioTarget
    if (duration && isFinite(duration)) {
      this.durationTarget.textContent = this.formatTime(duration)
    }
  }

  onEnded() {
    this.isPlaying = false
    this.updateButtonState()
    
    if (this.hasProgressTarget) {
      this.progressTarget.style.width = "0%"
    }
    
    if (this.hasCurrentTimeTarget) {
      this.currentTimeTarget.textContent = "0:00"
    }
    
    // Reset to beginning
    if (this.hasAudioTarget) {
      this.audioTarget.currentTime = 0
    }
  }

  onError(event) {
    console.error("Audio error:", event)
    this.isPlaying = false
    this.updateButtonState()
  }

  formatTime(seconds) {
    if (!seconds || !isFinite(seconds)) return "0:00"
    
    const mins = Math.floor(seconds / 60)
    const secs = Math.floor(seconds % 60)
    return `${mins}:${secs.toString().padStart(2, "0")}`
  }
}
