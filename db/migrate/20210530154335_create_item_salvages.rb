class CreateItemSalvages < ActiveRecord::Migration[6.1]
  def change
    create_table :item_salvages do |t|
      t.references :salvage_source, foreign_key: { to_table: :items }, index: false
      t.references :salvage_result, foreign_key: { to_table: :items }
      t.index [ 'salvage_source_id', 'salvage_result_id' ], unique: true
    end
    add_column :items, :salvage_result_count, :integer, limit: 2, default: 0
    add_column :items, :salvage_source_count, :integer, limit: 2, default: 0
  end
end
