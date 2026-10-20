import { Controller } from "@hotwired/stimulus"

// Renders a Cloudflare Turnstile widget. The script is loaded with
// render=explicit: its automatic rendering only happens on a full page load,
// so a form reached through Turbo would get no widget (and fail
// verification). Rendering it here works however the page arrived.
export default class extends Controller {
  static values = { sitekey: String, theme: { type: String, default: "light" } }

  async connect() {
    const turnstile = await turnstileLoaded()
    if (!this.element.isConnected) return

    // A page restored from Turbo's cache carries a copy of the old widget.
    this.element.replaceChildren()
    this.widgetId = turnstile.render(this.element, { sitekey: this.sitekeyValue, theme: this.themeValue })
  }

  disconnect() {
    if (this.widgetId !== undefined) window.turnstile?.remove(this.widgetId)
    this.widgetId = undefined
  }
}

function turnstileLoaded() {
  if (window.turnstile) return Promise.resolve(window.turnstile)

  const script = document.querySelector('script[src*="challenges.cloudflare.com/turnstile"]')
  return new Promise(resolve => {
    script.addEventListener("load", () => resolve(window.turnstile), { once: true })
  })
}
