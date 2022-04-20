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

import ItemFormController from "./controllers/item_form_controller"
import LunarRiftController from "./controllers/lunar_rift_controller"
import MoreLinkController from "./controllers/more-link-controller"
import RecipeController from "./controllers/recipe-controller"
import SelectNavController from "./controllers/select-nav-controller"
import SkillsBasicsController from "./controllers/skills_basics_controller"
import SkillsController from "./controllers/skills-controller"
import SkillsRollupController from "./controllers/skills-rollup-controller"

application.register("item-form", ItemFormController)
application.register("lunar-rift", LunarRiftController)
application.register("more-link", MoreLinkController)
application.register("recipe", RecipeController)
application.register("select-nav", SelectNavController)
application.register("skills-basics", SkillsBasicsController)
application.register("skills", SkillsController)
application.register("skills-rollup", SkillsRollupController)

application.register('autocomplete', Autocomplete)

LocalTime.start()

SotaLore.pageLoad(mousetrap_config)

const farming = new Farming()
SotaLore.pageLoad(() => farming.pageLoad())
