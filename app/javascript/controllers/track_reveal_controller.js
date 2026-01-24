import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["revealButton", "revealedInfo"]

  reveal() {
    if (this.hasRevealedInfoTarget) {
      this.revealedInfoTarget.classList.remove("hidden")
    }
    if (this.hasRevealButtonTarget) {
      this.revealButtonTarget.disabled = true
      this.revealButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
    }
  }
}
