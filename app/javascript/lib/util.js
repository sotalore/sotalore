export function updateText(element, text) {
  if (element.textContent == text) return
  element.textContent = text
}

const Quintillion = Math.pow(10, 18)
const Trillion = Math.pow(10, 12)

export function formatXP(xp) {
  if (Number.isInteger(xp)) {
    if (Math.abs(xp) >= Quintillion) {
      return xp.toExponential(3)
    } else if (Math.abs(xp) >= Trillion) {
      return (xp / this.Trillion).toFixed(3) + ' trillion'
    } else {
      return Intl.NumberFormat().format(xp)
    }
  } else {
    return xp
  }
}
