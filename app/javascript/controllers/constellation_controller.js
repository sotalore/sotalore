import { Controller } from "@hotwired/stimulus"
import Astronomy from "../lib/astronomy"

export default class extends Controller {

  static values = { offset: Number }

  connect() {
    this.refresh()
    this.startRefreshing()
  }

  disconnect() {
    this.stopRefreshing()
  }

  refresh() {
    const astronomy = new Astronomy()
    var [position, otherEdge] = astronomy.positionOfConstellation(this.offsetValue)
    this.element.textContent = Math.round(position) + "° - " + Math.round(otherEdge) + "°"
  }

  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, Astronomy.NB_MINUTE * 30000)
  }

  stopRefreshing() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

}
