# frozen_string_literal: true

class Adm::RecipesController < AdmController
  def retire
    recipe = Recipe.find(params[:id])
    authorize(recipe)
    recipe.retire!
    redirect_back_or_to recipe, notice: "Retired #{recipe.name}."
  end

  def unretire
    recipe = Recipe.find(params[:id])
    authorize(recipe, :retire?)
    recipe.unretire!
    redirect_back_or_to recipe, notice: "#{recipe.name} is no longer retired."
  end
end
