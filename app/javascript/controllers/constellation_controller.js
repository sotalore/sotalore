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
    let [trailingEdge, leadingEdge] = astronomy.positionOfConstellation(this.offsetValue)
    this.positionTarget.textContent = Math.round(trailingEdge) + "° - " + Math.round(leadingEdge) + "°"

    let timeToZenith = astronomy.timeToTravel(leadingEdge, 0, Astronomy.constellationOrbit)
    this.timeToZenithTarget.textContent = formatSeconds(timeToZenith)

    let note = ''
    if (trailingEdge < 90) {
      note = 'setting in east'
    } else if (leadingEdge > 270) {
      note = 'rising in west'
    } else if (leadingEdge < 90  && trailingEdge > 270) {
      note = 'at zenith'
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
