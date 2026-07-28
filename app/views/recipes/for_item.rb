# frozen_string_literal: true

class Views::Recipes::ForItem < Views::Base

  def initialize(recipes:)
    @recipes = recipes
  end

  def view_template
    @recipes.each do |recipe|
      render Components::Recipes::Card.new(recipe: recipe)
    end
  end

end
