import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    event.preventDefault()
    this.dialogTarget.classList.remove("hidden")
    this.dialogTarget.classList.add("flex")
  }

  close(event) {
    event.preventDefault()
    this.dialogTarget.classList.add("hidden")
    this.dialogTarget.classList.remove("flex")
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) {
      this.close(event)
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close(event)
    }
  }
}