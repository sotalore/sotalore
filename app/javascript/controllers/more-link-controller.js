import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = [ 'subDetail' ]

  load(event) {
    event.preventDefault()
    let url = event.currentTarget.dataset.url
    let more_id = event.currentTarget.dataset.moreId

    // event.currentTarget.classList.toggle('Displayed')
    console.log(event.currentTarget.getElementsByClassName('fas')[0])
    event.currentTarget.getElementsByClassName('fas')[0].classList.toggle('Displayed')

    let curr_element = document.getElementById(more_id)
    if (curr_element) {
      curr_element.classList.toggle('MoreHidden')
    } else {
      fetch(url)
      .then(response => response.text())
      .then((html) => {
        let container = document.createElement('div')
        container.id = more_id
        container.innerHTML = html
        this.subDetailTarget.prepend(container)
      })
    }
  }
}
