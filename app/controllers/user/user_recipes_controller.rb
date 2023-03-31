class User::UserRecipesController < ApplicationController

  before_action     :authenticate_user!
  skip_after_action :verify_authorized

  def create
    @recipe = find_recipe
    if @recipe
      unless find_user_recipe(@recipe.id)
        current_user.user_recipes
          .create!(recipe: @recipe)
      end
      render :create, layout: false
    else
      head :not_acceptable
    end
  end

  def destroy
    @recipe = find_recipe
    if ur = find_user_recipe
      ur.destroy
    end
    render :create, layout: false
  end

  private

  def find_recipe
    Recipe.find_by(id: params[:recipe_id])
  end

  def find_user_recipe(id=params[:recipe_id])
    current_user.user_recipes
      .find_by(recipe_id: id)
  end
end
