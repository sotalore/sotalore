import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ 'useSelect', 'useSpecific' ]

  connect() {
    this.displayUseSpecificFields()
  }

  change_use(event) {
    this.displayUseSpecificFields()
  }


  displayUseSpecificFields() {
    let currUse = this.useSelectTarget.value
    this.useSpecificTargets.forEach(fieldSet => {
      let uses = fieldSet.dataset.forUse.split(',')
      if (uses.includes(currUse)) {
        fieldSet.hidden = false
      } else {
        fieldSet.hidden = true
      }
    })
  }

}
