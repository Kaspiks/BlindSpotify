import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  toggle(event) {
    event.stopPropagation()
    
    if (this.contentTarget.classList.contains("hidden")) {
      this.open(event)
    } else {
      this.close()
    }
  }

  open(event) {
    const button = event.currentTarget
    const rect = button.getBoundingClientRect()
    
    this.contentTarget.style.top = `${rect.bottom + 8}px`
    this.contentTarget.style.left = `${Math.max(16, rect.left - 100)}px`
    
    this.contentTarget.classList.remove("hidden")
    document.addEventListener("click", this.closeOnClickOutside)
    document.addEventListener("keydown", this.closeOnEscape)
  }

  close() {
    this.contentTarget.classList.add("hidden")
    document.removeEventListener("click", this.closeOnClickOutside)
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
    document.removeEventListener("keydown", this.closeOnEscape)
  }
}
