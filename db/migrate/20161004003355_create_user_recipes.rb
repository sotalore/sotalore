class CreateUserRecipes < ActiveRecord::Migration[5.0]
  def change
    create_table :user_recipes do |t|
      t.references :user, foreign_key: true
      t.references :recipe, index: true, foreign_key: true

      t.timestamps
    end

    add_index :user_recipes, [ :user_id, :recipe_id ], unique: true
  end
end
