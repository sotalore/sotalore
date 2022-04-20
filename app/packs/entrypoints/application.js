/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

require("@rails/ujs").start()
require("turbolinks").start()

import { Autocomplete } from 'stimulus-autocomplete'

import SotaLore from "js/sota_lore"
import mousetrap_config from "js/mousetrap_config"
import LocalTime from "local-time"
import Farming from "js/farming"

import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

const application = Application.start()
const context = require.context("controllers", true, /.js$/)
application.load(definitionsFromContext(context))
application.register('autocomplete', Autocomplete)

LocalTime.start()

SotaLore.pageLoad(mousetrap_config)

const farming = new Farming()
SotaLore.pageLoad(() => farming.pageLoad())
