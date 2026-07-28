# frozen_string_literal: true

class Views::Adm::Styles::Base < Views::Base

  register_value_helper :item_use_tag
  register_value_helper :item_use_for_recipe_tag
  register_value_helper :item_abstract_tag
  register_value_helper :item_price_tag
  register_value_helper :item_gathering_tag
  register_value_helper :item_weight_tag

end
