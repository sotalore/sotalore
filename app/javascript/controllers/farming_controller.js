import { Controller } from "@hotwired/stimulus"

var moment = require('moment')

export default class extends Controller {
  static targets = [ 'startTime', 'segment1', 'segment2', 'endTime' ]

  static values = {
    seedTime: { type: Number, default: 8 },
    locationFactor: { type: Number, default: 1 },
  }

  connect() {
  }

  updateSeedTime(event) {
    this.seedTimeValue = event.target.value
  }

  updateLocationFactor(event) {
    this.locationFactorValue = event.target.value
  }

  seedTimeValueChanged(value, _) {
    this.update()
  }

  locationFactorValueChanged(value, _) {
    this.update()
  }

  update() {

    var baseTime = this.seedTimeValue * this.locationFactorValue;
    var startTime = moment()

    this.updateTargets(this.startTimeTargets, startTime)

    startTime.add(baseTime, "hours")
    this.updateTargets(this.segment1Targets, startTime)

    startTime.add(baseTime, "hours")
    this.updateTargets(this.segment2Targets, startTime)

    startTime.add(baseTime, "hours")
    this.updateTargets(this.endTimeTargets, startTime)
  }

  updateTargets(targets, time) {
    targets.forEach((e) => {
      e.innerHTML = this.describeTime(time)
    })
  }

  describeTime(time) {
    if (time.diff(moment(), 'days') >= 6) {
      return time.format('LLLL');
    } else {
      return time.calendar();
    }
  }

}
