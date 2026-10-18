import { Controller } from "@hotwired/stimulus"

// Checks a pasted skill code (see app/models/skill_code.rb) as it's pasted:
// which pages are there, which are still missing, and any page that didn't
// copy completely. The server checks it all again; this only saves a trip.
const PAGE = /SLS1\|(\d+)\/(\d+)\|(\d+)\|([o-])\|([^|]*)\|([0-9a-z]*)\|([0-9a-z]{2})/g

function check(entries) {
  let sum = 0
  for (const byte of new TextEncoder().encode(entries)) sum = (sum * 31 + byte) % 1296
  return sum.toString(36).padStart(2, "0")
}

export default class extends Controller {
  static targets = ["input", "status", "submit"]

  connect() {
    this.read()
  }

  read() {
    const text = this.inputTarget.value
    const pages = new Map()
    const problems = []
    let total = 0

    for (const [, number, of, , , , entries, sum] of text.matchAll(PAGE)) {
      if (check(entries) !== sum) {
        problems.push(`Page ${number} didn't copy completely: copy it again.`)
      } else {
        pages.set(Number(number), true)
        total = Number(of)
      }
    }

    const missing = []
    for (let page = 1; page <= total; page++) if (!pages.has(page)) missing.push(page)

    if (text.trim() === "") {
      this.show("", true)
    } else if (problems.length > 0) {
      this.show(problems.join(" "), false)
    } else if (total === 0) {
      this.show("That isn't a skill code yet: it starts with SLS1.", false)
    } else if (missing.length > 0) {
      this.show(`Got ${pages.size} of ${total} pages. Still to paste: page ${missing.join(", ")}.`, false)
    } else {
      this.show(total === 1 ? "Got the whole code." : `Got all ${total} pages.`, true)
    }
  }

  show(message, ready) {
    this.statusTarget.textContent = message
    this.submitTarget.disabled = !ready || this.inputTarget.value.trim() === ""
  }
}
