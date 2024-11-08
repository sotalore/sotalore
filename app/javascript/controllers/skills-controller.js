import { Controller } from "@hotwired/stimulus"

import { formatXP } from "../lib/util"

export default class extends Controller {
  static values = { xpFactor: Number, avatarUpdateUrl: String }

  static targets = ['from', 'to', 'current', 'total', 'remaining']

  static maxLevel = 32767

  connect() {
    this.originalFromValue = this.fromTarget.value
    this.originalToValue = this.toTarget.value
    this.calculateCurrent()
    this.calculateTotal()
  }

  calculateCurrent() {
    this.checkSkillLevel(this.fromTarget)
    this.currentXP = this.calculateXPForLevel(this.fromTarget.value)
    this.setXPValue('currentXP', this.currentTarget, this.currentXP)
    this.calculateRemaining()
  }

  calculateTotal() {
    this.checkSkillLevel(this.toTarget)
    this.totalXP = this.calculateXPForLevel(this.toTarget.value)
    this.setXPValue('totalXP', this.totalTarget, this.totalXP)
    this.calculateRemaining()
  }

  calculateRemaining() {
    let remainingXP = null
    if (this.currentXP && this.totalXP) {
      remainingXP = this.totalXP - this.currentXP
    } else if (this.totalXP) {
      remainingXP = this.totalXP
    } else if (this.currentXP) {
      remainingXP = -this.currentXP
    }
    this.setXPValue('remainingXP', this.remainingTarget, remainingXP)
  }

  setXPValue(field, targetElement, xp) {
    if (xp !== null) {
      targetElement.innerHTML = formatXP(xp)
      this.element.dataset[field] = xp
    } else {
      delete this.element.dataset[field]
      targetElement.innerHTML = formatXP('&nbsp;')
    }
    const event = new CustomEvent('skill:change', { bubbles: true })
    this.element.dispatchEvent(event)
  }

  calculateXPForLevel(level) {
    level = parseInt(level, 10)
    if (!Number.isInteger(level)) {
      return null
    }

    if (level === 0) {
      return 0
    }
    return (this.xpFactorValue * (Math.ceil(((1.099711 ** (level - 1)) - 1) * 100)))
  }

  updateFrom(event) {
    if (!this.checkSkillLevel(this.fromTarget)) {
      return
    }

    const newVal = this.fromTarget.value
    if (newVal !== this.originalFromValue) {
      this.updateEarnedSkill({ 'current': this.fromTarget.value })
      this.originalFromValue = newVal
    }
  }

  updateTo(event) {
    if (!this.checkSkillLevel(this.toTarget)) {
      return
    }

    const newVal = this.toTarget.value
    if (newVal !== this.originalToValue) {
      this.updateEarnedSkill({ 'target': this.toTarget.value })
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

  checkSkillLevel(element) {
    let level = element.value
    if (level === '') {
      element.classList.remove('error')
      return true
    }

    level = parseInt(level, 10)
    if (Number.isNaN(level) || level < 0 || level > this.constructor.maxLevel) {
      element.classList.add('error')
      return false
    }

    element.classList.remove('error')
    return true
  }

  getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`)
    return element.getAttribute("content")
  }
}
