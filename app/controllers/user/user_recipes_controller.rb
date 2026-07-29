class User::UserRecipesController < ApplicationController

  before_action     :authenticate_user!
  skip_after_action :verify_authorized

  layout false, only: [ :create, :destroy ]

  def create
    @recipe = find_recipe
    if @recipe
      unless find_user_recipe(@recipe.id)
        Current.user.user_recipes.find_or_create_by!(recipe: @recipe)
      end
      render Views::User::UserRecipes::Button.new(recipe: @recipe)
    else
      head :not_acceptable
    end
  end

  def destroy
    @recipe = find_recipe
    if ur = find_user_recipe
      ur.destroy
    end
    render Views::User::UserRecipes::Button.new(recipe: @recipe)
  end

  private

  def find_recipe
    Recipe.find_by(id: params[:recipe_id])
  end

  def find_user_recipe(id=params[:recipe_id])
    Current.user.user_recipes.find_by(recipe_id: id)
  end
end
