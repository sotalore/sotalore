import { Controller } from "@hotwired/stimulus"
import Astronomy from "../lib/astronomy"
import { formatSeconds } from "../lib/time_util"
import { updateText } from "../lib/util"

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
    let [leadingEdge, trailingEdge] = astronomy.positionOfConstellation(this.offsetValue)
    updateText(this.positionTarget, Math.round(leadingEdge) + "° - " + Math.round(trailingEdge) + "°")

    let timeToZenith = astronomy.timeToTravel(leadingEdge, 0, Astronomy.constellationOrbit)

    let note = ''
    if (leadingEdge > 330) {
      note = 'at zenith'
      timeToZenith = 0
    } else if (leadingEdge < 90) {
      note = 'rising in east'
    } else if (trailingEdge > 270) {
      note = 'setting in west'
    }
    updateText(this.noteTarget, note)
    updateText(this.timeToZenithTarget, formatSeconds(timeToZenith))
  }


  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, Astronomy.nbMinute * 30000)
  }

  stopRefreshing() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

}
