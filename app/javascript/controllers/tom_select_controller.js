import { Controller } from "@hotwired/stimulus"
import "tom-select"

/**
 * Tom Select Stimulus controller
 *
 * Enhances a plain <select> into a searchable, styled dropdown.
 *
 * Usage:
 *   <select data-controller="tom-select">
 *   <div data-controller="tom-select"> (first <select> inside is used)
 *
 * Configuration (Stimulus values):
 *   data-tom-select-search-value="false"           — disable search
 *   data-tom-select-placeholder-value="Pick one…"  — placeholder text
 *   data-tom-select-allow-empty-value="true"       — allow clearing selection
 */
export default class extends Controller {
  static values = {
    search:     { type: Boolean, default: true },
    placeholder:{ type: String,  default: "Search…" },
    allowEmpty: { type: Boolean, default: true }
  }

  connect() {
    const el = this.element.tagName === "SELECT"
      ? this.element
      : this.element.querySelector("select")

    if (!el) return
    this.selectEl = el

    this.instance = new window.TomSelect(el, {
      controlInput: this.searchValue ? undefined : null,
      placeholder: this.placeholderValue,
      allowEmptyOption: this.allowEmptyValue,
      sortField: { field: "text", direction: "asc" },
      plugins: ["dropdown_input"]
    })
  }

  disconnect() {
    if (this.instance) {
      this.instance.destroy()
      this.instance = null
    }
  }

  // Public actions
  reset() {
    this.instance?.clear()
  }
}
