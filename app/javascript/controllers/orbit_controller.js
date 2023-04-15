import { Controller } from "@hotwired/stimulus"
import Astronomy  from "../lib/astronomy"
import { updateText } from "../lib/util"

export default class extends Controller {

  static values = { period: Number }

  static targets = [ "note", "position" ]

  connect() {
    this.refresh()
    this.startRefreshing()
  }

  disconnect() {
    this.stopRefreshing()
  }

  refresh() {
    const astronomy = new Astronomy()
    const orbitalPeriod = this.periodValue * Astronomy.nbDay
    const position = astronomy.positionOfPlanet(orbitalPeriod)
    var note = ""

    if (position >= 0 && position <= 90) {
      note = 'rising in east'
    } else if (position > 270) {
      note = 'setting in west'
    }

    if (this.hasNoteTarget) {
      updateText(this.noteTarget, note)
    }

    if (this.hasPositionTarget) {
      updateText(this.positionTarget, position.toFixed(2))
    }
  }

  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, Astronomy.nbMinute * 1000)
  }

  stopRefreshing() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

}