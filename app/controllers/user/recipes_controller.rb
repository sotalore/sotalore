class User::RecipesController < RecipesController

  before_action     :authenticate_user!
  skip_after_action :verify_authorized

  private
  def recipe_scope
    Current.user.recipes
  end
end
