class RecipesProduceItems < ActiveRecord::Migration[5.0]
  def change
    change_table(:recipes) do |t|
      t.integer :item_id
      t.integer :item_count, null: false, default: 1
    end
  end
end
