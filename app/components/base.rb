# frozen_string_literal: true

class Components::Base < Phlex::HTML
  include Components

  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::AssetPath
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::Pluralize
  include Phlex::Rails::Helpers::FieldSetTag

  register_value_helper :policy
  register_value_helper :l
  register_value_helper :page_title
  register_value_helper :current_user
  register_value_helper :current_skills_path

  register_output_helper :tile
  register_output_helper :tile_body
  register_output_helper :tile_heading
  register_output_helper :tile_with_heading
  register_output_helper :render_flash_messages
  register_output_helper :site_nav_link_to
  register_output_helper :phlex_paginate
  register_output_helper :sl_form_for
  register_output_helper :formatted_body
  register_output_helper :primary_button_to
  register_output_helper :new_button_to
  register_output_helper :edit_button_to
  register_output_helper :destroy_button_to
  register_output_helper :back_button_to
  register_output_helper :edit_icon_to
  register_output_helper :destroy_icon_to
  register_output_helper :layout_main_content
  register_output_helper :user_flair_tag
  register_output_helper :local_time_ago
  register_output_helper :time_ago_tag

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
