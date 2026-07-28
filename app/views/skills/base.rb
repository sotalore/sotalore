# frozen_string_literal: true

class Views::Skills::Base < Views::Base

  register_output_helper :page_heading_tab
  register_output_helper :avatar_select_tag
  register_value_helper :avatar_visible_skills

end
