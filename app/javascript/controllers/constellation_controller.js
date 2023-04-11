import { Controller } from "@hotwired/stimulus"
import Astronomy from "../lib/astronomy"
import { formatSeconds } from "../lib/time_util"

export default class extends Controller {

  static targets = [ 'position', 'timeToZenith', 'note' ]
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
    let [position, otherEdge] = astronomy.positionOfConstellation(this.offsetValue)
    this.positionTarget.textContent = Math.round(position) + "° - " + Math.round(otherEdge) + "°"

    let timeToZenith = astronomy.timeToTravel(otherEdge, 0, Astronomy.constellationOrbit)
    this.timeToZenithTarget.textContent = formatSeconds(timeToZenith)

    let note = ''
    if (position < 90) {
      note = 'setting in east'
    } else if (otherEdge > 270) {
      note = 'rising in west'
    }
    this.noteTarget.textContent = note
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
