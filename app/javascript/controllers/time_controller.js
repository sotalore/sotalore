import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  // This is not year zero, but year 400, when the avatars arrived (again)
  EPOCH = Math.floor(new Date("January 1, 2013 00:00:00 -0000").getTime() / 1000)

  NB_HOUR = (60 * 60) / 24   // 150 seconds ... 1 game-hour is 1/24th of an hour
  NB_MINUTE = this.NB_HOUR / 60.0 // 2.5 seconds

  NB_DAY = 60 * 60         // 1 game-day is 1 hour
  NB_MONTH = 28 * this.NB_DAY   // 1 game-month is 28 game-days
  NB_YEAR = 12 * this.NB_MONTH  // 1 game-year is 12 game-months (14 days)

  MONTHS = [ 'Janus', 'Februa', 'Marse', 'Apru', 'Maia', 'Juno', 'Julius', 'Augus', 'Septembre', 'Octobre', 'Novembre', 'Decembre' ];

  connect() {
    this.refresh()
    this.startRefreshing()
  }

  disconnect() {
    this.stopRefreshing()
  }

  refresh() {
    this.element.textContent = this.current_time_to_nbt()
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


  current_time_to_nbt() {
    let now = new Date()

    var seconds = (now.getTime() / 1000) - this.EPOCH
    // this will be year relative from the epoch
    let year = Math.floor(seconds / this.NB_YEAR)
    seconds -= year * this.NB_YEAR
    // year is now relative to PC (post-cataclysm)
    year += 400

    let month = Math.floor(seconds / this.NB_MONTH)
    seconds -= month * this.NB_MONTH

    let day = Math.floor(seconds / this.NB_DAY) + 1

    let in_utc = new Date(now.toUTCString())

    let seconds_since_top_of_hour = (in_utc.getMinutes() * 60) + in_utc.getSeconds()

    let hour = Math.floor(seconds_since_top_of_hour / this.NB_HOUR)
    seconds_since_top_of_hour -= hour * this.NB_HOUR
    let minute = Math.floor(seconds_since_top_of_hour / this.NB_MINUTE)

    return `${this.MONTHS[month]} ${day}, ${year}PC ${this.pad(hour)}:${this.pad(minute)}`
  }

  pad(n) {
    return n < 10 ? '0' + n : n
  }
}