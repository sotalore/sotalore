/* eslint no-console:0 */

require("@rails/ujs").start()
require("turbolinks").start()

import { Autocomplete } from 'stimulus-autocomplete'

import SotaLore from "./js/sota_lore"
import mousetrap_config from "./js/mousetrap_config"
import LocalTime from "local-time"
import Farming from "./js/farming"

import { Application } from "@hotwired/stimulus"

const application = Application.start()
const context = require.context("controllers", true, /.js$/)
application.load(definitionsFromContext(context))
application.register('autocomplete', Autocomplete)

LocalTime.start()

SotaLore.pageLoad(mousetrap_config)

const farming = new Farming()
SotaLore.pageLoad(() => farming.pageLoad())
