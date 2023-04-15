export function updateText(element, text) {
  if (element.textContent == text) return
  element.textContent = text
}