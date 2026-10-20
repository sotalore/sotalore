import { Controller } from "@hotwired/stimulus"
import { formatXP } from "lib/util"

const FIELDS = [ 'currentXP', 'totalXP', 'remainingXP' ]

// Adds up the XP of the skill table's rows: each skill into its school's
// row, each school into its category's row, and each category into the
// totals. A member names the row it adds into with data-rollup-target, and
// a skill row says it changed with a skill:change event, which bubbles up to
// here.
//
// Changes are added up once per batch: a page load or a morph changes every
// row at once, and totalling the groups for each of those took seconds.
export default class extends Controller {

  static targets = [ 'member' ]

  connect() {
    // The skill rows may have connected first, and their changes went
    // unheard.
    this.rollUpAll()
  }

  memberChanged() {
    this.scheduleRollUp()
  }

  // A skill row removed (ignoring it) takes its XP out of its group.
  memberTargetDisconnected() {
    this.scheduleRollUp()
  }

  scheduleRollUp() {
    if (this.rollUpScheduled) return

    this.rollUpScheduled = true
    queueMicrotask(() => {
      this.rollUpScheduled = false
      if (this.element.isConnected) this.rollUpAll()
    })
  }

  // Totals every group, each after the groups inside it. The members are
  // looked up each time, since rows come and go.
  rollUpAll() {
    const groups = new Map()
    this.memberTargets.forEach(member => {
      const id = member.dataset.rollupTarget
      if (!groups.has(id)) groups.set(id, [])
      groups.get(id).push(member)
    })

    const done = new Set()
    const rollUp = (id) => {
      if (done.has(id)) return
      done.add(id)

      const members = groups.get(id) || []
      // A school or category row adds up its own group first (which may
      // now be empty).
      members.forEach(member => { if (!this.isSkillRow(member)) rollUp(member.id) })

      const rollupTarget = document.getElementById(id)
      if (rollupTarget) FIELDS.forEach(field => this.rollupSingleValue(rollupTarget, members, field))
    }
    groups.forEach((_members, id) => rollUp(id))
  }

  isSkillRow(member) {
    return member.matches('[data-controller~="skills"]')
  }

  rollupSingleValue(rollupTarget, members, field) {
    let sum = 0
    members.forEach(member => {
      if (member.dataset[field] !== undefined) {
        sum = sum + parseInt(member.dataset[field], 10)
      }
    })
    let txt = ''
    if (sum != 0) {
      rollupTarget.dataset[field] = sum
      txt = formatXP(sum)
    } else {
      delete rollupTarget.dataset[field]
    }
    for (let ele of rollupTarget.getElementsByClassName(field)) {
      ele.innerHTML = txt
    }
  }
}
