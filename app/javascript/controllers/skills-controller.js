import { Controller } from "stimulus"

export default class extends Controller {
  static values = { xpFactor: Number }

  static targets = [ 'from', 'to', 'invested', 'total', 'remaining' ]

  calculateFrom() {
    this.investedTarget.innerHTML = ''
    this.investedXP = null

    let fromLevel = parseInt(this.fromTarget.value, 10)
    if (Number.isInteger(fromLevel) && fromLevel > 0) {
      this.investedXP = this.XPToLevel(fromLevel)
      this.investedTarget.innerHTML = Intl.NumberFormat().format(this.investedXP)
    }
    this.calculateRemaining()
  }

  calculateTo() {
    this.totalTarget.innerHTML = ''
    this.totalXP = null

    let toLevel = parseInt(this.toTarget.value, 10)
    if (Number.isInteger(toLevel) && toLevel > 0) {
      this.totalXP = this.XPToLevel(toLevel)
      this.totalTarget.innerHTML = Intl.NumberFormat().format(this.totalXP)
    }
    this.calculateRemaining()
  }

  calculateRemaining() {
    this.remainingTarget.innerHTML = ''
    if (this.investedXP && this.totalXP) {
      this.remainingTarget.innerHTML = Intl.NumberFormat().format(this.totalXP - this.investedXP)
    }
  }


  XPToLevel(level) {
    if (level == 0) {
      return 0
    }
    return (this.xpFactorValue * (Math.ceil(((1.099711**(level-1)) - 1) * 100)))
  }
}