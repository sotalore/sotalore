import { Controller } from "@hotwired/stimulus"

// A "select all" checkbox for a list of checkboxes:
//
//   <div data-controller="check-all">
//     <input type="checkbox" data-action="check-all#toggle">
//     <input type="checkbox" data-check-all-target="box"> ...
export default class extends Controller {
  static targets = ["box"]

  toggle(event) {
    this.boxTargets.forEach((box) => { box.checked = event.target.checked })
  }
}
