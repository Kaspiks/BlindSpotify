import { Controller } from "@hotwired/stimulus"

// Scan deck: capture from camera or upload image, POST to deck_scan, show tracks grouped by year.
export default class extends Controller {
  static values = {
    scanUrl: String,
    csrfToken: String
  }

  static targets = [
    "panel", "cameraVideo", "fileInput",
    "captureBtn", "uploadLabel", "loading", "result", "error", "yearGroup"
  ]

  connect() {
    this.stream = null
  }

  disconnect() {
    this.stopCamera()
  }

  openPanel() {
    if (this.hasPanelTarget) this.panelTarget.classList.remove("hidden")
    this.startCamera()
  }

  closePanel() {
    if (this.hasPanelTarget) this.panelTarget.classList.add("hidden")
    this.stopCamera()
    if (this.hasResultTarget) this.resultTarget.classList.add("hidden")
    if (this.hasErrorTarget) this.errorTarget.classList.add("hidden")
  }

  async startCamera() {
    if (!this.hasCameraVideoTarget) return
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" } })
      this.cameraVideoTarget.srcObject = this.stream
    } catch (e) {
      console.warn("Camera not available:", e)
      if (this.hasCaptureBtnTarget) this.captureBtnTarget.classList.add("hidden")
    }
  }

  stopCamera() {
    if (this.stream) {
      this.stream.getTracks().forEach((t) => t.stop())
      this.stream = null
    }
    if (this.hasCameraVideoTarget && this.cameraVideoTarget.srcObject) {
      this.cameraVideoTarget.srcObject = null
    }
  }

  captureFromCamera() {
    if (!this.hasCameraVideoTarget || !this.cameraVideoTarget.srcObject) return
    const video = this.cameraVideoTarget
    const canvas = document.createElement("canvas")
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    canvas.getContext("2d").drawImage(video, 0, 0)
    canvas.toBlob((blob) => this.submitImage(blob), "image/png", 0.92)
  }

  onFileSelected(event) {
    const file = event.target.files?.[0]
    if (!file || !file.type.startsWith("image/")) return
    this.submitImage(file)
    event.target.value = ""
  }

  async submitImage(blobOrFile) {
    const url = this.scanUrlValue
    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
    if (!url) return

    this.setLoading(true)
    if (this.hasErrorTarget) this.errorTarget.classList.add("hidden")
    if (this.hasResultTarget) this.resultTarget.classList.add("hidden")

    const form = new FormData()
    form.append("image", blobOrFile)

    try {
      const res = await fetch(url, {
        method: "POST",
        body: form,
        headers: {
          "X-CSRF-Token": token || this.csrfTokenValue || "",
          "Accept": "application/json"
        }
      })
      const data = await res.json().catch(() => ({}))
      this.setLoading(false)

      if (!res.ok) {
        this.showError(data.error || "Scan failed")
        return
      }

      this.renderTracks(data.tracks || [])
    } catch (e) {
      this.setLoading(false)
      this.showError(e.message || "Network error")
    }
  }

  setLoading(on) {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.toggle("hidden", !on)
    }
    if (this.hasCaptureBtnTarget) this.captureBtnTarget.disabled = on
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  renderTracks(tracks) {
    if (!this.hasResultTarget) return
    const byYear = {}
    tracks.forEach((t) => {
      const year = t.release_year != null ? String(t.release_year) : "Unknown year"
      if (!byYear[year]) byYear[year] = []
      byYear[year].push(t)
    })
    const years = Object.keys(byYear).sort((a, b) => {
      if (a === "Unknown year") return 1
      if (b === "Unknown year") return -1
      return Number(a) - Number(b)
    })

    let html = ""
    years.forEach((year) => {
      html += `<div class="mb-4"><h4 class="text-purple-400 font-semibold mb-2">${escapeHtml(year)}</h4><ul class="space-y-1 text-slate-300 text-sm">`
      byYear[year].forEach((t) => {
        html += `<h1>${escapeHtml(t.position)}</h1>`
        html += `<li>${escapeHtml(t.artist_name)} – ${escapeHtml(t.title)}</li>`
      })
      html += "</ul></div>"
    })

    this.resultTarget.innerHTML = html || "<p class=\"text-slate-500\">No cards detected. Try better lighting or hold cards flat.</p>"
    this.resultTarget.classList.remove("hidden")
  }
}

function escapeHtml(s) {
  const div = document.createElement("div")
  div.textContent = s
  return div.innerHTML
}
