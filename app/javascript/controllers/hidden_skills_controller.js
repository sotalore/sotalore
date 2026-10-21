import { Controller } from "@hotwired/stimulus"

// Saves the hidden skills page's changes as they're made: a skill's checkbox
// hides or reveals it, and a school's buttons hide or reveal all its skills.
// A change shows at once, with a spinner in its row until it's saved, then a
// check that fades away. If it fails, it's undone and the row shows a
// warning. Saves go one at a time, in order, so quick clicks land in the
// order they were made.
export default class extends Controller {
  static targets = [ 'school', 'skill', 'count', 'total' ]

  connect() {
    this.queue = Promise.resolve()
  }

  toggle(event) {
    const box = event.target
    const hide = box.checked
    const row = box.closest('[data-row]')
    this.markHidden(row, hide)
    this.save(row, hide ? box.dataset.hideUrl : box.dataset.revealUrl, () => this.markHidden(row, !hide))
  }

  // A school's Hide all and Reveal all buttons are forms, for when there's no
  // JavaScript.
  saveSchool(event) {
    event.preventDefault()
    const form = event.target
    const hide = event.params.hide
    const school = this.schoolTargets.find(school => school.contains(form))
    const rows = this.skillTargets.filter(row => school.contains(row))
    const before = rows.map(row => this.isHidden(row))
    rows.forEach(row => this.markHidden(row, hide))
    this.save(form.closest('[data-row]'), form.action, () => rows.forEach((row, i) => this.markHidden(row, before[i])))
  }

  save(row, url, undo) {
    const status = row.querySelector('[data-save-status]')
    status.pending = (status.pending || 0) + 1
    this.showStatus(status, 'saving')

    this.queue = this.queue.then(async () => {
      let saved = false
      try {
        const response = await fetch(url, {
          method: 'PATCH',
          credentials: 'same-origin',
          headers: { 'X-CSRF-Token': this.csrfToken, 'Accept': 'application/json' },
        })
        // Signed out, it's redirected to the sign-in page.
        saved = response.ok && !response.redirected
      } catch {
        saved = false
      }

      status.pending -= 1
      if (!saved) {
        undo()
        this.showStatus(status, 'failed')
      } else if (status.pending === 0) {
        this.showStatus(status, 'done')
      }
    })
  }

  isHidden(row) {
    return row.querySelector('input[type="checkbox"]').checked
  }

  markHidden(row, hide) {
    row.querySelector('input[type="checkbox"]').checked = hide
    row.classList.toggle('opacity-50', hide)
    this.updateCounts()
  }

  updateCounts() {
    this.schoolTargets.forEach(school => {
      const count = this.skillTargets.filter(row => school.contains(row) && this.isHidden(row)).length
      this.countTargets.find(target => school.contains(target)).textContent = this.hiddenText(count)
    })
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = this.hiddenText(this.skillTargets.filter(row => this.isHidden(row)).length)
    }
  }

  hiddenText(count) {
    return count === 0 ? '' : `${count} hidden`
  }

  // Shows the status's icon for the state (saving, done or failed), and
  // fades the done check away after a moment.
  showStatus(status, state) {
    clearTimeout(status.fadeTimer)
    status.querySelectorAll('[data-state]').forEach(icon => {
      icon.classList.toggle('hidden', icon.dataset.state !== state)
      icon.classList.remove('opacity-0')
    })

    if (state === 'done') {
      const check = status.querySelector('[data-state="done"]')
      status.fadeTimer = setTimeout(() => {
        check.classList.add('opacity-0')
        status.fadeTimer = setTimeout(() => check.classList.add('hidden'), 700)
      }, 1000)
    }
  }

  get csrfToken() {
    return document.head.querySelector('meta[name="csrf-token"]')?.content
  }
}
