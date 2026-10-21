import { Controller } from "@hotwired/stimulus"

// An image upload form that also takes pasted screenshots: paste anywhere on
// the page (other than into a text field), or use the Paste button, which a
// phone or tablet needs. Pasted and chosen images are previewed before they're
// uploaded, in case one shows something it shouldn't, and each can be removed,
// or all of them cleared.
//
// The images all go into the form's file input, so the form uploads them as it
// would chosen files (ActiveStorage's direct upload included). The page comes
// back by morphing, which keeps this controller (and its files) but puts back
// the form as the server rendered it, so it's emptied once uploaded and shown
// again after the morph.
export default class extends Controller {
  static targets = [ "input", "previews", "template", "paste", "clear", "submit", "message" ]

  connect() {
    this.files = []
    this.render()
  }

  disconnect() {
    this.revokePreviews()
  }

  // The file input's own picker replaces its files, so the chosen ones are
  // added to those already there.
  choose() {
    this.add(Array.from(this.inputTarget.files))
  }

  paste(event) {
    if (this.isEditable(event.target)) return

    const images = Array.from(event.clipboardData?.files || []).filter(this.isImage)
    if (images.length == 0) return

    event.preventDefault()
    this.add(images.map(file => this.named(file)))
  }

  async pasteFromClipboard() {
    try {
      const images = []
      for (const item of await navigator.clipboard.read()) {
        const type = item.types.find(type => type.startsWith("image/"))
        if (type) images.push(this.named(await item.getType(type)))
      }
      if (images.length == 0) return this.say("There's no image on the clipboard.")
      this.add(images)
    } catch {
      this.say("The clipboard couldn't be read. Allow this site to read it, or choose the image instead.")
    }
  }

  uploaded(event) {
    if (event.detail.success) this.files = []
  }

  morphed() {
    this.render()
  }

  remove(event) {
    this.files.splice(Number(event.params.index), 1)
    this.render()
  }

  clear() {
    this.files = []
    this.render()
  }

  // private

  add(files) {
    this.files.push(...files.filter(this.isImage))
    this.render()
  }

  render() {
    const transfer = new DataTransfer()
    this.files.forEach(file => transfer.items.add(file))
    this.inputTarget.files = transfer.files

    this.revokePreviews()
    this.previewsTarget.replaceChildren(...this.files.map((file, index) => this.preview(file, index)))

    const none = this.files.length == 0
    this.pasteTarget.hidden = !navigator.clipboard?.read
    this.clearTarget.hidden = none
    this.submitTarget.disabled = none
    this.say("")
  }

  preview(file, index) {
    const preview = this.templateTarget.content.firstElementChild.cloneNode(true)
    const image = preview.querySelector("img")
    image.src = URL.createObjectURL(file)
    image.alt = file.name
    const name = preview.querySelector("[data-name]")
    name.textContent = name.title = file.name
    preview.querySelector("[data-size]").textContent = this.size(file)
    preview.querySelector("button").dataset.imageUploadIndexParam = index
    return preview
  }

  revokePreviews() {
    this.previewsTarget.querySelectorAll("img").forEach(image => URL.revokeObjectURL(image.src))
  }

  // A pasted image is named "image.png", whatever it is, so it's named for
  // when it was pasted instead.
  named(blob) {
    const now = new Date()
    const digits = parts => parts.map(part => String(part).padStart(2, "0")).join("")
    const stamp = `${digits([ now.getFullYear(), now.getMonth() + 1, now.getDate() ])}-${digits([ now.getHours(), now.getMinutes(), now.getSeconds() ])}`
    const extension = blob.type.split("/")[1]?.replace("jpeg", "jpg") || "png"
    return new File([ blob ], `screenshot-${stamp}.${extension}`, { type: blob.type })
  }

  isImage(file) {
    return file.type.startsWith("image/")
  }

  isEditable(element) {
    return element.closest?.("input, textarea, select, [contenteditable]") && element != this.inputTarget
  }

  size(file) {
    const kb = file.size / 1024
    return kb < 1024 ? `${Math.round(kb)} KB` : `${(kb / 1024).toFixed(1)} MB`
  }

  say(message) {
    this.messageTarget.textContent = message
    this.messageTarget.hidden = message == ""
  }
}
