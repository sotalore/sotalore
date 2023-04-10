import { Controller } from "@hotwired/stimulus"
import Astronomy from "../lib/astronomy"

export default class extends Controller {

  months = [ 'Janus', 'Februa', 'Marse', 'Apru', 'Maia', 'Juno', 'Julius', 'Augus', 'Septembre', 'Octobre', 'Novembre', 'Decembre' ];

  connect() {
    this.refresh()
    this.startRefreshing()
  }

  disconnect() {
    this.stopRefreshing()
  }

  refresh() {
    this.element.textContent = this.currentTimeToPC()
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


  currentTimeToPC() {
    const now = new Date()

    let seconds = (now.getTime() / 1000) - Astronomy.beginningOfPC
    // this will be year relative from the epoch
    const year = Math.floor(seconds / Astronomy.nbYear)
    seconds -= year * Astronomy.nbYear

    const month = Math.floor(seconds / Astronomy.nbMonth)
    seconds -= month * Astronomy.nbMonth

    const day = Math.floor(seconds / Astronomy.nbDay) + 1

    const nowUTC = new Date(now.toUTCString())

    let secondsSinceTopOfHour = (nowUTC.getMinutes() * 60) + nowUTC.getSeconds()

    let hour = Math.floor(secondsSinceTopOfHour / Astronomy.nbHour)
    secondsSinceTopOfHour -= hour * Astronomy.nbHour
    let minute = Math.floor(secondsSinceTopOfHour / Astronomy.nbMinute)

    return `${this.months[month]} ${day}, ${year}PC ${this.pad(hour)}:${this.pad(minute)}`
  }

  pad(n) {
    return n < 10 ? '0' + n : n
  }
}