import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static values = { offset: Number }

  NB_MINUTE = 2.5 // seconds
  NB_HOUR = 60 * this.NB_MINUTE // 150 seconds ... 1 game-hour is 1/24th of an hour
  NB_DAY = 24 * this.NB_HOUR // 1 hour
  NB_MONTH = 28 * this.NB_DAY // 28 hours
  NB_YEAR = 12 * this.NB_MONTH // 336 hours == 14 days

  // This is not year zero, but year 400, when the avatars arrived (again)
  EPOCH = Math.floor(new Date("January 1, 2013 00:00:00 -0000").getTime() / 1000)
  BEGINNING_OF_PC = this.EPOCH - (400 * this.NB_YEAR)

  ORBITAL_PERIOD = 6 * this.NB_MONTH

  connect() {
    this.refresh()
    this.startRefreshing()
  }

  disconnect() {
    this.stopRefreshing()
  }

  refresh() {
    this.element.textContent = this.positionOfConstellation().toFixed(3)
  }

  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, this.NB_MINUTE * 1000)
  }

  stopRefreshing() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

  positionOfConstellation() {
    var now = new Date()
    var rt_seconds = (now.getTime() / 1000) - this.BEGINNING_OF_PC
    var remainder = (rt_seconds % this.ORBITAL_PERIOD)
    var zeroEdge = (remainder / this.ORBITAL_PERIOD)
    var position = zeroEdge + this.offsetValue
    if (position > 359) {
      position -= 360
    }
    return position
  }

}