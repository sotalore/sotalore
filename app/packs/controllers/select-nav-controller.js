import { Controller } from "stimulus"

export default class extends Controller {

  connect() {
    this.selectElement = this.element.querySelector('select')
    if (this.selectElement) {
      this.selectElement.addEventListener('change', (event) => { this.navChanged(event) })
    }
  }

  navChanged(e) {
    window.location = e.target.value
  }
}