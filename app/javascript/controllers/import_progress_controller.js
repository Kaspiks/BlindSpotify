import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    playlistId: Number
  }
  static targets = ["progressBar", "progressText"]

  connect() {
    // Start polling for status updates
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    // Poll every 1.5 seconds
    this.checkStatus()
    this.pollInterval = setInterval(() => this.checkStatus(), 1500)
  }

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
  }

  async checkStatus() {
    try {
      const response = await fetch(`/playlists/${this.playlistIdValue}/status.json`)
      if (!response.ok) return
      
      const data = await response.json()
      
      // Update progress bar if we have targets
      if (this.hasProgressBarTarget && data.tracks_count > 0) {
        const bar = this.progressBarTarget.querySelector('div')
        if (bar) {
          bar.style.width = `${data.progress}%`
        }
      }
      
      if (this.hasProgressTextTarget && data.tracks_count > 0) {
        this.progressTextTarget.textContent = `${data.imported_tracks_count} / ${data.tracks_count} tracks imported`
      }
      
      if (data.status === "completed" || data.status === "failed") {
        this.stopPolling()
        this.reloadPage()
      }
    } catch (error) {
      console.error("Error checking import status:", error)
    }
  }

  reloadPage() {
    // Small delay to ensure everything is updated
    setTimeout(() => {
      window.location.reload()
    }, 300)
  }
}
