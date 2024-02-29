import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['startTime', 'segment1', 'segment2', 'endTime', 'windowTime',
    'exportCalendar', 'exportName', 'copyCalendarUrlMessage', 'calendarHelp']

  static values = {
    seedTime: { type: Number, default: 8 },
    locationFactor: { type: Number, default: 1 },
    exportCalendarBaseUrl: { type: String, default: '' },
    exportCalendarUrl: { type: String, default: '' },
  }

  connect() {
    console.log(navigator.languages)
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

    const windowSize = this.seedTimeValue * this.locationFactorValue;
    this.windowTimeTargets.forEach((e) => {
      e.innerHTML = windowSize + " hours"
    })

    const startTime = new Date()
    var nextTime = this.addHours(startTime, 0)

    this.updateTargets(this.startTimeTargets, nextTime)

    nextTime = this.addHours(nextTime, windowSize)
    this.updateTargets(this.segment1Targets, nextTime)

    nextTime = this.addHours(nextTime, windowSize)
    this.updateTargets(this.segment2Targets, nextTime)

    nextTime = this.addHours(nextTime, windowSize)
    this.updateTargets(this.endTimeTargets, nextTime)

    this.buildCalendarUrl(startTime)

  }

  addHours(date, hours) {
    return new Date(date.getTime() + (hours * 60 * 60 * 1000))
  }

  buildCalendarUrl(startTime) {
    var startTimeStr = this.formatDateForCalendar(startTime)

    var url = new URL(this.exportCalendarBaseUrlValue, window.location.origin)
    url.searchParams.set('start', startTimeStr)
    url.searchParams.set('seedTime', this.seedTimeValue)
    url.searchParams.set('locationFactor', this.locationFactorValue)
    url.searchParams.set('name', this.exportNameTarget.value)
    this.exportCalendarUrlValue = url.toString()
  }

  copyCalendarUrl(event) {
    event.stopPropagation()
    event.preventDefault()
    navigator.clipboard.writeText(this.exportCalendarUrlValue)
    this.copyCalendarUrlMessageTarget.classList.remove('opacity-0', 'hidden')
    setTimeout(() => {
      this.copyCalendarUrlMessageTarget.classList.add('opacity-0', 'hidden')
    }, 3500)
  }

  updateTargets(targets, time) {
    targets.forEach((e) => {
      e.innerHTML = this.describeTime(time)
    })
  }

  describeTime(time) {
    const today = new Date()
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)
    const nextWeek = new Date(today)
    nextWeek.setDate(nextWeek.getDate() + 6)

    if (this.isToday(time)) {
      return this.formatTodayTomorrow(0, time)
    } else if (this.isTomorrow(time)) {
      return this.formatTodayTomorrow(1, time)
    } else if (time < nextWeek) {
      return this.formatThisWeek(time)
    } else {
      return this.formatFuture(time)
    }
  }

  formatTodayTomorrow(offset, time) {
    const rtf = new Intl.RelativeTimeFormat(navigator.languages, { numeric: "auto" });
    const formatter = Intl.DateTimeFormat(navigator.languages, { hour: 'numeric', minute: '2-digit' })
    return rtf.format(offset, 'day') + ' ' + formatter.format(time)
  }

  formatThisWeek(time) {
    const formatter = Intl.DateTimeFormat(navigator.languages, { weekday: 'short', hour: 'numeric', minute: '2-digit' })
    return formatter.format(time)
  }

  formatFuture(time) {
    const formatter = Intl.DateTimeFormat(navigator.languages, {
      weekday: 'short', month: 'short', day: 'numeric',
      hour: 'numeric', minute: '2-digit'
    })
    return formatter.format(time)
  }

  showCalendarHelp(event) {
    event.stopPropagation()
    event.preventDefault()
    this.calendarHelpTarget.classList.remove('hidden')
  }

  formatDateForCalendar(date) {
    var tzo = -date.getTimezoneOffset(),
      dif = tzo >= 0 ? '+' : '-',
      pad = function (num) {
        return (num < 10 ? '0' : '') + num;
      };

    return date.getFullYear() +
      '-' + pad(date.getMonth() + 1) +
      '-' + pad(date.getDate()) +
      'T' + pad(date.getHours()) +
      ':' + pad(date.getMinutes()) +
      ':' + pad(date.getSeconds()) +
      dif + pad(Math.floor(Math.abs(tzo) / 60)) +
      ':' + pad(Math.abs(tzo) % 60);
  }

  isToday(date) {
    const today = new Date();
    return date.getDate() === today.getDate() &&
      date.getMonth() === today.getMonth() &&
      date.getFullYear() === today.getFullYear();
  }

  isTomorrow(date) {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    return date.getDate() === tomorrow.getDate() &&
      date.getMonth() === tomorrow.getMonth() &&
      date.getFullYear() === tomorrow.getFullYear();
  }
}
