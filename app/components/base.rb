# frozen_string_literal: true

class Components::Base < Phlex::HTML
  include Components

  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::AssetPath
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::Pluralize
  include Phlex::Rails::Helpers::FieldSetTag
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::TurboFrameTag

  register_value_helper :policy
  register_value_helper :l
  register_value_helper :page_title
  register_value_helper :current_skills_path

  register_output_helper :tile
  register_output_helper :tile_body
  register_output_helper :tile_heading
  register_output_helper :tile_with_heading
  register_output_helper :render_flash_messages
  register_output_helper :sl_form_for
  register_output_helper :formatted_body
  register_output_helper :primary_button_to
  register_output_helper :default_button_to
  register_output_helper :new_button_to
  register_output_helper :edit_button_to
  register_output_helper :destroy_button_to
  register_output_helper :back_button_to
  register_output_helper :edit_icon_to
  register_output_helper :destroy_icon_to
  register_output_helper :view_icon_to
  register_output_helper :more_link_to
  register_output_helper :layout_main_content
  register_output_helper :flair_primary
  register_output_helper :flair_info
  register_output_helper :flair_danger
  register_output_helper :flair_success
  register_output_helper :flair_warning
  register_output_helper :notice_info
  register_output_helper :notice_danger
  register_output_helper :notice_success
  register_output_helper :notice_warning
  register_output_helper :local_time_ago
  register_output_helper :time_ago_tag
  register_output_helper :render_comments_for

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
