import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Top-bar search: visits the result chosen in the autocomplete list.
export default class extends Controller {
  visit(event) {
    Turbo.visit(event.detail.value)
  }
}
