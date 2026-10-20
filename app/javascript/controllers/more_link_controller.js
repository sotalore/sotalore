import { Controller } from "@hotwired/stimulus"

// Shows or hides the recipe for an ingredient under it. The recipe is in a
// lazy frame, so Turbo loads it the first time it's shown.
export default class extends Controller {
  toggle(event) {
    event.preventDefault()
    event.currentTarget.classList.toggle('Displayed')
    const frame = document.getElementById(event.params.frame)
    frame.hidden = !frame.hidden
  }
}
