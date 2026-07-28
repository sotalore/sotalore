# frozen_string_literal: true

class Views::User::UserRecipes::Create < Views::Base

  register_output_helper :user_recipe_button

  def initialize(recipe:)
    @recipe = recipe
  end

  def view_template
    user_recipe_button(@recipe)
  end

end
