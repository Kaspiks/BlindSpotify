import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, refreshUrl: String }
  static targets = ["playIcon", "pauseIcon"]

  connect() {
    this.audio = null
    this.isPlaying = false
    this.hasTriedRefresh = false
  }

  disconnect() {
    this.stop()
    if (this.audio) {
      this.audio.removeEventListener("ended", this.boundOnEnded)
      this.audio.removeEventListener("error", this.boundOnError)
      this.audio = null
    }
  }

  toggle(event) {
    event.preventDefault()

    if (this.isPlaying) {
      this.stop()
    } else {
      this.play()
    }
  }

  play() {
    document.querySelectorAll("[data-controller='audio-preview']").forEach(el => {
      const controller = this.application.getControllerForElementAndIdentifier(el, "audio-preview")
      if (controller && controller !== this) {
        controller.stop()
      }
    })

    this.ensureAudio(this.urlValue)

    const playPromise = this.audio.play()

    if (playPromise !== undefined) {
      playPromise
        .then(() => {
          this.isPlaying = true
          this.updateIcon()
        })
        .catch((error) => {
          if (error.name === "AbortError") return
          console.warn("[AudioPreview] play() rejected:", error.message)
          this.attemptRefreshAndRetry()
        })
    } else {
      this.isPlaying = true
      this.updateIcon()
    }
  }

  stop() {
    if (this.audio) {
      this.audio.pause()
      this.audio.currentTime = 0
    }
    this.isPlaying = false
    this.updateIcon()
  }

  // Do not set crossOrigin for Deezer/iTunes preview URLs: their CDNs often return
  // 403 when the request is CORS-mode (anonymous) from arbitrary Origins.
  // Playback without crossOrigin still works; we are not reading samples via canvas/Web Audio.
  ensureAudio(url) {
    if (!this.audio) {
      this.audio = new Audio()
      this.audio.preload = "auto"
      this.boundOnEnded = () => this.stop()
      this.boundOnError = () => this.attemptRefreshAndRetry()
      this.audio.addEventListener("ended", this.boundOnEnded)
      this.audio.addEventListener("error", this.boundOnError)
    }

    if (this.audio.src !== url) {
      this.audio.src = url
      this.audio.load()
    }
  }

  async attemptRefreshAndRetry() {
    if (this.hasTriedRefresh || !this.hasRefreshUrlValue || !this.refreshUrlValue) {
      this.isPlaying = false
      this.updateIcon()
      return
    }

    this.hasTriedRefresh = true

    try {
      const res = await fetch(this.refreshUrlValue, {
        headers: { Accept: "application/json" },
      })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const data = await res.json()

      if (data.preview_url) {
        this.urlValue = data.preview_url
        this.audio.src = data.preview_url
        this.audio.load()

        const retryPromise = this.audio.play()
        if (retryPromise !== undefined) {
          retryPromise
            .then(() => { this.isPlaying = true; this.updateIcon() })
            .catch(() => { this.isPlaying = false; this.updateIcon() })
        }
        return
      }
    } catch (e) {
      console.warn("[AudioPreview] refresh failed:", e.message)
    }

    this.isPlaying = false
    this.updateIcon()
  }

  updateIcon() {
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
}
