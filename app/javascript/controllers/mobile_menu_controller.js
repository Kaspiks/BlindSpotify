import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button", "openIcon", "closeIcon"]

  connect() {
    this.isOpen = false
  }

  toggle() {
    this.isOpen = !this.isOpen

    if (this.isOpen) {
      this.menuTarget.classList.remove("hidden")
      this.openIconTarget.classList.add("hidden")
      this.closeIconTarget.classList.remove("hidden")
    } else {
      this.menuTarget.classList.add("hidden")
      this.openIconTarget.classList.remove("hidden")
      this.closeIconTarget.classList.add("hidden")
    }
  }

  close() {
    this.isOpen = false
    this.menuTarget.classList.add("hidden")
    this.openIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
  }
}