class CreateItemSalvages < ActiveRecord::Migration[6.1]
  def change
    create_table :item_salvages do |t|
      t.references :salvage_from, foreign_key: { to_table: :items }, index: false, null: false
      t.references :salvage_to, foreign_key: { to_table: :items }, null: false
      t.index [ 'salvage_from_id', 'salvage_to_id' ], unique: true
    end
    add_column :items, :salvage_from_count, :integer, limit: 2, default: 0, null: false
    add_column :items, :salvage_to_count, :integer, limit: 2, default: 0, null: false
  end
end
