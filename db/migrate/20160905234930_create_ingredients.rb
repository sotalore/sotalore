class CreateIngredients < ActiveRecord::Migration[5.0]
  def change
    create_table :ingredients do |t|
      t.belongs_to :recipe, null: false, index: false, foreign_key: true
      t.belongs_to :item, null: false, index: true, foreign_key: true
      t.integer    :count, null: false, default: 1
      t.timestamps
    end
    add_index :ingredients, [ :recipe_id, :item_id ], unique: true
  end
end
