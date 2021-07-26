import { Controller } from "stimulus"

export default class extends Controller {
  static values = { url: String }

  load(event) {
    event.preventDefault()
    fetch(this.urlValue)
      .then(response => response.text())
      .then(html => this.element.innerHTML = html)
  }
}