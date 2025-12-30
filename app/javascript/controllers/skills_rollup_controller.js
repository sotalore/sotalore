import { Controller } from "@hotwired/stimulus"
import { formatXP } from "lib/util"

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
    const eles = rollupTarget.getElementsByClassName(field)
    let sum = 0
    this.rollupGroups[rollupTarget.id].forEach((e) => {
      if (e.dataset[field] !== undefined) {
        sum = sum + parseInt(e.dataset[field], 10)
      }
    })
    let txt  =  ''
    if (sum != 0) {
      rollupTarget.dataset[field] = sum
      txt = formatXP(sum)
    } else {
      delete rollupTarget.dataset[field]
    }
    for (let ele of eles) {
      ele.innerHTML = txt
    }
  }
}
