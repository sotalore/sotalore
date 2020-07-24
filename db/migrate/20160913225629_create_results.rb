class CreateResults < ActiveRecord::Migration[5.0]
  def change
    create_table :results do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :item, null: false, index: true, foreign_key: true
      t.integer    :count, null: false, default: 1
      t.timestamps
    end
    add_index :results, [ :recipe_id, :item_id ], unique: true

    remove_column :recipes, :item_id, :integer
    remove_column :recipes, :item_count, :integer
  end
end
