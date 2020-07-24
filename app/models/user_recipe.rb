class UserRecipe < ApplicationRecord
  belongs_to :user, inverse_of: :user_recipes
  belongs_to :recipe, inverse_of: :user_recipes
end
