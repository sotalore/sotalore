import { Controller } from "stimulus"

export default class extends Controller {
  static values = { xpFactor: Number, avatarUpdateUrl: String }

  static targets = [ 'from', 'to', 'invested', 'total', 'remaining' ]

  connect() {
    this.originalFromValue = this.fromTarget.value
    this.originalToValue = this.toTarget.value
  }

  calculateFrom() {
    this.investedTarget.innerHTML = ''
    this.investedXP = null

    const fromLevel = parseInt(this.fromTarget.value, 10)
    if (Number.isInteger(fromLevel) && fromLevel > 0) {
      this.investedXP = this.XPToLevel(fromLevel)
      this.investedTarget.innerHTML = Intl.NumberFormat().format(this.investedXP)
    }
    this.calculateRemaining()
  }

  calculateTo() {
    this.totalTarget.innerHTML = ''
    this.totalXP = null

    const toLevel = parseInt(this.toTarget.value, 10)
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

  updateFrom(event) {
    const newVal = this.fromTarget.value
    if (newVal !== this.originalFromValue) {
      this.updateEarnedSkill({'current': this.fromTarget.value})
      this.originalFromValue = newVal
    }
  }

  updateTo(event) {
    const newVal = this.toTarget.value
    if (newVal !== this.originalToValue) {
      this.updateEarnedSkill({'target': this.toTarget.value})
      this.originalToValue = newVal
    }
  }

  updateEarnedSkill(skill_data) {
    if (this.avatarUpdateUrlValue) {
      let data = { 'skill': skill_data }
      fetch(this.avatarUpdateUrlValue, {
        method: 'PATCH',
        credentials: "same-origin",
        headers: {
          "X-CSRF-Token": this.getMetaValue("csrf-token"),
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
      })
    }
  }

  getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`)
    return element.getAttribute("content")
  }
}
