# frozen_string_literal: true

class Views::User::UserRecipes::Button < Views::Base

  def initialize(recipe:)
    @recipe = recipe
  end

  CSS_CLASS = "UserRecipeStar"
  EXISTS_CLASS = "UserRecipeStar--exists"

  def view_template
    return if Current.user.null?

    exists = Current.user.user_recipes.find_by(recipe: @recipe)
    # Starring updates just this frame, from the star the controller renders.
    turbo_frame_tag([ dom_id(Current.user), dom_id(@recipe) ].join("-")) do
      if exists
        star_button(user_user_recipe_path(exists, recipe_id: @recipe), :delete, "Remove from My Recipes", [ CSS_CLASS, EXISTS_CLASS ])
      else
        star_button(user_user_recipes_path(recipe_id: @recipe), :post, "Add to My Recipes", [ CSS_CLASS ])
      end
    end
  end

  private

  def star_button(path, method, title, css_class)
    button_to(path, method: method, class: [ *css_class, "cursor-pointer" ], title: title, form: { class: "contents" }) do
      i { safe('&nbsp;') }
    end
  end

end
