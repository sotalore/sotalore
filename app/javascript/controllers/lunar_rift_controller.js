import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "rift" ]

  single_duration = (8 * 60) + 45;
  full_cycle = ((8 * 60) + 45) * 8;
  // skew happened somewhere, which is the -40
  epoch = Math.floor(new Date("January 1, 2013 00:00:00 -0000").getTime() / 1000) - 40;

  connect() {
    this.refresh()
    this.startRefreshing()
  }

  disconnect() {
    this.stopRefreshing()
  }

  refresh() {
    let e = this.elapsed();
    for (let rift of this.riftTargets) {
      let el = $(rift)
      let idx = parseInt(el.data("index"), 10)
      let w = this.where_is(idx, e);
      if (w < 0) {
        el.addClass('active')
        el.find('div').html(this.minutes_and_seconds(-1 * w))
      } else {
        el.removeClass('active')
        el.find('div').html(this.minutes_and_seconds(w))
      }
    }
  }

  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, 1000)
  }

  stopRefreshing() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

  elapsed() {
    let now =  Math.floor(new Date().getTime() / 1000)
    return (now - this.epoch) % this.full_cycle
  }

  where_is(idx, elapsed) {
    let end_time = (idx * this.single_duration)
    let beg_time = (idx * this.single_duration) - this.single_duration

    if (elapsed >= beg_time && elapsed < end_time) {
      // active
      return -(end_time - elapsed)
    } else if (elapsed < beg_time) {
      // in this cycle, but later
      return beg_time - elapsed
    } else {
      // in next cycle
      return this.full_cycle - elapsed + beg_time
    }
  }

  minutes_and_seconds(i) {
    let s = i % 60
    let m = Math.floor((i - s) / 60)
    return "" + this.padded(m) + ":" + this.padded(s)
  }

  padded(i) {
    if (i < 10) {
      return "0" + i
    } else {
      return "" + i
    }
  }
}
