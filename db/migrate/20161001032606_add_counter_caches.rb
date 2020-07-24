class AddCounterCaches < ActiveRecord::Migration[5.0]
  def change
    add_column :items, :ingredients_count, :integer, null: false, default: 0
    add_column :items, :results_count, :integer, null: false, default: 0
    add_column :recipes, :ingredients_count, :integer, null: false, default: 0
    add_column :recipes, :results_count, :integer, null: false, default: 0
  end
end
