# frozen_string_literal: true

class Views::Items::Base < Views::Base

  register_output_helper :item_use_tag
  register_output_helper :item_use_specific_tags
  register_output_helper :item_abstract_tag
  register_output_helper :item_price_tag
  register_output_helper :item_gathering_tag
  register_output_helper :item_weight_tag

  register_value_helper :abstract_items_options

end
