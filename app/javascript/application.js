import "@hotwired/turbo-rails"
import "controllers"
import "trix"
import "@rails/actiontext"
import * as ActiveStorage from "@rails/activestorage"
import LocalTime from "local-time"
import { Autocomplete } from 'stimulus-autocomplete'
import Lightbox from "@stimulus-components/lightbox"

ActiveStorage.start()
LocalTime.start()

// When Turbo refreshes a page by morphing, a <details> stays open or closed
// the way the viewer left it, rather than as the server rendered it.
document.addEventListener("turbo:before-morph-attribute", (event) => {
  if (event.target instanceof HTMLDetailsElement && event.detail.attributeName === "open") event.preventDefault()
})

window.Stimulus.register('autocomplete', Autocomplete)
window.Stimulus.register("lightbox", Lightbox)
