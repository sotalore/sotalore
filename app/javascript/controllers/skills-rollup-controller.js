import { Controller } from "stimulus"

export default class extends Controller {

  static targets = [ 'member' ]

  connect() {
    this.rollupGroups = {}
    this.memberTargets.forEach(element => {
      const rollupTarget = element.dataset['rollupTarget']
      if (this.rollupGroups[rollupTarget] === undefined) {
        this.rollupGroups[rollupTarget] = []
      }
      this.rollupGroups[rollupTarget].push(element)
      element.addEventListener('skill:change', ev => this.onSkillChange(ev))
    })
  }

  onSkillChange(event) {
    event.stopPropagation()
    const rollupTarget = event.currentTarget.dataset['rollupTarget']
    this.updateRollupTarget(rollupTarget)
  }


  updateRollupTarget(rollupTargetId) {
    const rollupTarget = document.getElementById(rollupTargetId)
    this.rollupSingleValue(rollupTarget, 'currentXP')
    this.rollupSingleValue(rollupTarget, 'totalXP')
    this.rollupSingleValue(rollupTarget, 'remainingXP')
    const nextEvent = new CustomEvent('skill:change', { bubbles: true })
    rollupTarget.dispatchEvent(nextEvent)
  }

  rollupSingleValue(rollupTarget, field) {
    const ele = rollupTarget.getElementsByClassName(field)[0]
    let sum = 0
    this.rollupGroups[rollupTarget.id].forEach((e) => {
      if (e.dataset[field] !== undefined) {
        sum = sum + parseInt(e.dataset[field], 10)
      }
    })
    if (sum > 0) {
      rollupTarget.dataset[field] = sum
      ele.innerHTML = Intl.NumberFormat().format(sum)
    } else {
      delete rollupTarget.dataset[field]
      ele.innerHTML = ''
    }
  }
}
