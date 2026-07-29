# frozen-string-literal: true

module UserRecipesHelper

  def user_recipe_button(recipe)
    return if Current.user.null?
    exists = Current.user.user_recipes.find_by(recipe: recipe)
    css_class = "UserRecipeStar"
    turbo_frame_tag([dom_id(Current.user), dom_id(recipe)].join("-")) do
      if exists
        css_class += " UserRecipeStar--exists"
        data_attr = { turbo_method: 'delete' }
        link_to(user_user_recipe_path(exists, recipe_id: recipe), class: css_class, data: data_attr) do
          content_tag(:i, raw('&nbsp;'))
        end
      else
        data_attr = { turbo_method: 'post' }
        link_to(user_user_recipes_path(recipe_id: recipe), class: css_class, data: data_attr) do
          content_tag(:i, raw('&nbsp;'))
        end
      end
    end
  end

end