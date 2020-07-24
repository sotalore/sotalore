class AddRecipeKeyToRecipes < ActiveRecord::Migration[5.0]
  def change
    add_column :recipes, :recipe_key, :string
  end
end
