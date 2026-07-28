# frozen_string_literal: true

class Views::Recipes::Edit < Views::Base

  def initialize(recipe:)
    @recipe = recipe
  end

  def view_template
    tile do
      tile_heading("Edit Recipe: #{@recipe.name}") { default_button_to("Cancel", @recipe) }
      tile_body do
        render Views::Recipes::Form.new(recipe: @recipe)
      end
    end
  end

end
