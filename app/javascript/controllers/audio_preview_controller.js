import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["playIcon", "pauseIcon"]

  connect() {
    this.audio = null
    this.isPlaying = false
  }

  disconnect() {
    this.stop()
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
    // Stop any other playing previews
    document.querySelectorAll("[data-controller='audio-preview']").forEach(el => {
      const controller = this.application.getControllerForElementAndIdentifier(el, "audio-preview")
      if (controller && controller !== this) {
        controller.stop()
      }
    })

    if (!this.audio) {
      this.audio = new Audio(this.urlValue)
      this.audio.addEventListener("ended", () => this.stop())
      this.audio.addEventListener("error", (e) => {
        console.error("Audio preview error:", e)
        this.stop()
      })
    }

    const playPromise = this.audio.play()
    
    if (playPromise !== undefined) {
      playPromise
        .then(() => {
          this.isPlaying = true
          this.updateIcon()
        })
        .catch((error) => {
          console.error("Audio preview playback failed:", error)
          this.isPlaying = false
          this.updateIcon()
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
