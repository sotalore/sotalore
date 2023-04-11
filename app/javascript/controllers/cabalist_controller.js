import { Controller } from "@hotwired/stimulus"
import Astronomy  from "../lib/astronomy"
import { formatSeconds } from "../lib/time_util"

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

        const remainingTime = astronomy.timeToTravel(trailing, position, orbitalPeriod)
        this.timeRemainingTarget.textContent = formatSeconds(remainingTime)

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

}