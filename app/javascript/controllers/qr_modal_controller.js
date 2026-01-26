import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "image", "title", "downloadLink"]

  open(event) {
    event.preventDefault()
    
    const url = event.params.url
    const title = event.params.title || "QR Code"
    
    this.imageTarget.src = url
    this.titleTarget.textContent = title
    this.downloadLinkTarget.href = url
    
    this.dialogTarget.classList.remove("hidden")
    this.dialogTarget.classList.add("flex")
    
    document.body.style.overflow = "hidden"
  }

  close(event) {
    if (event) event.preventDefault()
    
    this.dialogTarget.classList.add("hidden")
    this.dialogTarget.classList.remove("flex")
    
    document.body.style.overflow = ""
    
    this.imageTarget.src = ""
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) {
      this.close(event)
    }
  }
}
