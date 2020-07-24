class AddTeachableToRecipes < ActiveRecord::Migration[5.2]
  def change
    add_column :recipes, :teachable, :smallint
  end
end
