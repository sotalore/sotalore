import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ 'useSelect', 'useSpecific' ]

  connect() {
    if (typeof turnstile !== 'undefined') {
      // turnstile.implicitRender()
    }
  }

}
