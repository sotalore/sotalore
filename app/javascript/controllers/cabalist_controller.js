import { Controller } from "@hotwired/stimulus"
import Astronomy  from "../lib/astronomy"

export default class extends Controller {

  static values = { period: Number }

  static targets = [ "currentCity", "symbol", "virtue", "timeRemaining", "nextCity" ]

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

    const constellations = astronomy.currentConstellations()
    for (const constellation of constellations) {
      let [trailing, leading] = constellation.position
      if (this.isInArc(position, trailing, leading)) {
        this.currentCityTarget.textContent = constellation.city
        this.symbolTarget.textContent = constellation.symbol
        this.virtueTarget.textContent = constellation.virtue

        const remainingTime = this.remainingTime(position, trailing, leading, orbitalPeriod)
        this.timeRemainingTarget.textContent = this.formatSeconds(remainingTime)

        const nextConstellation = astronomy.nextConstellation(constellation.symbol)
        this.nextCityTarget.textContent = nextConstellation.city
        break
      }
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

  isInArc(position, trailing, leading) {
    if (trailing > leading) {
      // The arc is crossing the 0°/360° meridian
      return (position >= trailing || position <= leading)
    } else {
      return (position >= trailing && position <= leading)
    }
  }

  remainingTime(position, trailing, leading, period) {
    const degrees = this.remainingDegrees(position, trailing, leading)
    const secondPerDegree = period / 360
    return degrees * secondPerDegree
  }

  remainingDegrees(position, trailing, leading) {
    if (trailing > leading) {
      // The arc is crossing the 0°/360° meridian
      if (position >= trailing) {
        return position - trailing
      } else {
        return 360 - position - trailing
      }
    } else {
      return position - trailing
    }
  }

  formatSeconds(seconds) {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = Math.floor(seconds % 60)
    if (minutes > 59) {
      const hours = Math.floor(minutes / 60)
      const remainingMinutes = Math.floor(minutes % 60)
      return `${hours}:${this.pad(remainingMinutes)}:${this.pad(remainingSeconds)}`
    }
    return `${minutes}:${this.pad(remainingSeconds)}`
  }

  pad(n) {
    return n < 10 ? '0' + n : n
  }

}