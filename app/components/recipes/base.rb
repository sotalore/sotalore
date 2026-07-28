# frozen_string_literal: true

class Components::Recipes::Base < Components::Base

  register_output_helper :craft_skill_tag
  register_output_helper :item_price_tag
  register_output_helper :item_gathering_tag
  register_output_helper :item_abstract_tag
  register_output_helper :item_use_for_recipe_tag

end
