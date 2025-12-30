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

window.Stimulus.register('autocomplete', Autocomplete)
window.Stimulus.register("lightbox", Lightbox)
