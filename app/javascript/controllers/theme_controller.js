import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "theme"
const MODES = ["light", "dark", "system"]

// Keeps <html class="dark"> in sync with the selected light/dark/system
// preference. The initial class is set synchronously by an inline script in
// the document <head> (to avoid a flash); this controller takes over from
// there, reacts to option clicks, and tracks OS-level scheme changes while
// "system" is selected.
export default class extends Controller {
  static targets = ["option"]

  connect() {
    this.media = window.matchMedia("(prefers-color-scheme: dark)")
    this.onSystemChange = this.onSystemChange.bind(this)
    this.media.addEventListener("change", this.onSystemChange)
    this.refresh()
  }

  disconnect() {
    this.media.removeEventListener("change", this.onSystemChange)
  }

  onSystemChange() {
    if (this.mode() === "system") this.applyDarkClass()
  }

  set(event) {
    localStorage.setItem(STORAGE_KEY, event.params.mode)
    this.refresh()
  }

  refresh() {
    this.applyDarkClass()
    this.markActiveOption()
  }

  applyDarkClass() {
    document.documentElement.classList.toggle("dark", this.isDark())
  }

  isDark() {
    const mode = this.mode()
    if (mode === "dark") return true
    if (mode === "light") return false
    return this.media.matches
  }

  mode() {
    const stored = localStorage.getItem(STORAGE_KEY)
    return MODES.includes(stored) ? stored : "system"
  }

  markActiveOption() {
    const current = this.mode()
    this.optionTargets.forEach((el) => {
      el.classList.toggle("is-active", el.dataset.themeModeParam === current)
    })
  }
}
