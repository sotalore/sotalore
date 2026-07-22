# frozen_string_literal: true

class Components::Base < Phlex::HTML
  include Components

  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::AssetPath
  include Phlex::Rails::Helpers::LinkTo

  register_value_helper :policy
  register_value_helper :l
  register_value_helper :page_title
  register_value_helper :current_user
  register_value_helper :current_skills_path

  register_output_helper :tile
  register_output_helper :tile_body
  register_output_helper :render_flash_messages
  register_output_helper :site_nav_link_to

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
