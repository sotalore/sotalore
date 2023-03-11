import { Controller } from "@hotwired/stimulus"

var moment = require('moment')

export default class extends Controller {
  static targets = [ 'startTime', 'segment1', 'segment2', 'endTime', 'exportCalendar', 'exportName' ]

  static values = {
    seedTime: { type: Number, default: 8 },
    locationFactor: { type: Number, default: 1 },
    exportCalendarBaseUrl: { type: String, default: '' },
    exportCalendarUrl: { type: String, default: ''},
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

  exportCalendarUrlValueChanged(value, _) {
    this.exportCalendarTarget.href = value
  }

  update() {

    var baseTime = this.seedTimeValue * this.locationFactorValue;
    var startTime = moment()
    var startTimeStr = startTime.format('YYYY-MM-DDTHH:mm:ssZZ')

    this.updateTargets(this.startTimeTargets, startTime)

    startTime.add(baseTime, "hours")
    this.updateTargets(this.segment1Targets, startTime)

    startTime.add(baseTime, "hours")
    this.updateTargets(this.segment2Targets, startTime)

    startTime.add(baseTime, "hours")
    this.updateTargets(this.endTimeTargets, startTime)

    this.buildCalendarUrl(startTimeStr)

  }

  buildCalendarUrl(startTime) {
    var url = new URL(this.exportCalendarBaseUrlValue, window.location.origin)
    url.searchParams.set('start', startTime)
    url.searchParams.set('seedTime', this.seedTimeValue)
    url.searchParams.set('locationFactor', this.locationFactorValue)
    url.searchParams.set('name', this.exportNameTarget.value)
    this.exportCalendarUrlValue = url.toString()
  }

  copyCalendarUrl(event) {
    event.stopPropagation()
    event.preventDefault()
    navigator.clipboard.writeText(this.exportCalendarUrlValue)
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
