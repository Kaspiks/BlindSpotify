import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    text: String,
    successMessage: { type: String, default: "Copied!" },
    label: String
  }

  static targets = ["label"]

  copy(event) {
    event.preventDefault()
    const text = this.textValue
    if (!text) return

    navigator.clipboard.writeText(text).then(() => {
      this.showFeedback()
    }).catch(() => {
      this.fallbackCopy(text)
    })
  }

  showFeedback() {
    if (this.hasLabelTarget && this.labelValue) {
      const labelEl = this.labelTarget
      const originalText = labelEl.textContent
      labelEl.textContent = this.successMessageValue
      this.element.disabled = true
      setTimeout(() => {
        labelEl.textContent = this.labelValue
        this.element.disabled = false
      }, 1500)
    } else {
      const originalContent = this.element.innerHTML
      this.element.innerHTML = this.successMessageValue
      this.element.disabled = true
      setTimeout(() => {
        this.element.innerHTML = originalContent
        this.element.disabled = false
      }, 1500)
    }
  }

  // Used when navigator.clipboard.writeText fails (e.g. non-HTTPS). execCommand is deprecated
  // but remains the only way to copy in those contexts; there is no other standard API.
  fallbackCopy(text) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.setAttribute("readonly", "")
    textarea.style.position = "absolute"
    textarea.style.left = "-9999px"
    document.body.appendChild(textarea)
    textarea.select()
    try {
      const doc = /** @type { { execCommand(cmd: string) => boolean } } */ (document)
      const copied = doc.execCommand("copy")
      if (copied) this.showFeedback()
    } finally {
      document.body.removeChild(textarea)
    }
  }
}
