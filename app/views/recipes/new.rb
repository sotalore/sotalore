# frozen_string_literal: true

class Views::Recipes::New < Views::Base

  def initialize(recipe:)
    @recipe = recipe
  end

  def view_template
    tile do
      tile_heading("Add New Recipe") { default_button_to("Cancel", recipes_path) }
      tile_body do
        render Views::Recipes::Form.new(recipe: @recipe)
      end
    end
  end

end
