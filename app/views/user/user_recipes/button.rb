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
    turbo_frame_tag([ dom_id(Current.user), dom_id(@recipe) ].join("-")) do
      if exists
        a(href: user_user_recipe_path(exists, recipe_id: @recipe), class: [ CSS_CLASS, EXISTS_CLASS ], data: { turbo_method: 'delete' }) do
          i { safe('&nbsp;') }
        end
      else
        a(href: user_user_recipes_path(recipe_id: @recipe), class: [ CSS_CLASS ], data: { turbo_method: 'post' }) do
          i { safe('&nbsp;') }
        end
      end
    end
  end

end
