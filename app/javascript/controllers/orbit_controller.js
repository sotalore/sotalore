import { Controller } from "@hotwired/stimulus"
import Astronomy  from "../lib/astronomy"

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
    const orbitalPeriod = this.periodValue * Astronomy.nbDay
    const position = Astronomy.positionOfPlanet(orbitalPeriod)
    var note = ""

    if (position >= 0 && position <= 90) {
      note = 'rising in east'
    } else if (position > 270) {
      note = 'setting in west'
    }

    if (this.hasNoteTarget) {
      this.noteTarget.textContent = note
    }

    if (this.hasPositionTarget) {
      this.positionTarget.textContent = position.toFixed(2)
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