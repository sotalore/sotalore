/* eslint no-console:0 */

import "@hotwired/turbo-rails"
import "trix"
import "@rails/actiontext"

import SotaLore from "./js/sota_lore"
import mousetrap_config from "./js/mousetrap_config"
import LocalTime from "local-time"
import turnstilePageLoad from "./js/turnstile"

import { Application } from "@hotwired/stimulus"
window.Stimulus = Application.start()

import { Autocomplete } from 'stimulus-autocomplete'
window.Stimulus.register('autocomplete', Autocomplete)

import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

import FarmingController from "./controllers/farming_controller"
import ItemFormController from "./controllers/item_form_controller"
import LunarRiftController from "./controllers/lunar_rift_controller"
import MoreLinkController from "./controllers/more-link-controller"
import RecipeController from "./controllers/recipe-controller"
import SelectNavController from "./controllers/select-nav-controller"
import SkillsBasicsController from "./controllers/skills_basics_controller"
import SkillsController from "./controllers/skills-controller"
import SkillsRollupController from "./controllers/skills-rollup-controller"

window.Stimulus.register("farming", FarmingController)
window.Stimulus.register("item-form", ItemFormController)
window.Stimulus.register("lunar-rift", LunarRiftController)
window.Stimulus.register("more-link", MoreLinkController)
window.Stimulus.register("recipe", RecipeController)
window.Stimulus.register("select-nav", SelectNavController)
window.Stimulus.register("skills-basics", SkillsBasicsController)
window.Stimulus.register("skills", SkillsController)
window.Stimulus.register("skills-rollup", SkillsRollupController)

LocalTime.start()

SotaLore.pageLoad(mousetrap_config)
SotaLore.pageLoad(turnstilePageLoad)
