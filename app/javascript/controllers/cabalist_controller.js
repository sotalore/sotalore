import { Controller } from "@hotwired/stimulus"
import Astronomy  from "../lib/astronomy"
import { formatSeconds } from "../lib/time_util"
import { updateText } from "../lib/util"

export default class extends Controller {

  static values = { period: Number, offset: { type: Number, default: 0} }

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
    const position = astronomy.positionOfPlanet(orbitalPeriod) + this.offsetValue

    const constellations = astronomy.currentConstellations()
    for (const constellation of constellations) {
      let [leading, trailing] = constellation.position
      if (astronomy.isInArc(position, leading, trailing)) {
        updateText(this.currentCityTarget, constellation.city)
        updateText(this.symbolTarget, constellation.symbol)
        updateText(this.virtueTarget, constellation.virtue)

        const remainingTime = astronomy.timeToTravel(position, leading, orbitalPeriod)
        updateText(this.timeRemainingTarget, formatSeconds(remainingTime))

        const nextConstellation = astronomy.nextConstellation(constellation.symbol)
        updateText(this.nextCityTarget, nextConstellation.city)
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

}