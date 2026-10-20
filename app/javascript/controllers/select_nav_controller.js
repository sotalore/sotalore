import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Goes to the page chosen in a <select> whose option values are URLs.
export default class extends Controller {
  navigate(event) {
    Turbo.visit(event.target.value)
  }
}
