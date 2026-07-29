# frozen_string_literal: true

class Views::Farmings::Base < Views::Base

  register_output_helper :local_time
  register_output_helper :item_price_tag
  register_output_helper :options_for_select

end
