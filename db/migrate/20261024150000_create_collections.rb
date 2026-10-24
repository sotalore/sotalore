class CreateCollections < ActiveRecord::Migration[8.1]
  # Site-curated ways of grouping items ("Light Armor", "Poison Potions"),
  # apart from the game's groups and categories. A collection lists items
  # and can sit inside other collections, more than one at a time ("Fortified
  # Leather Armor" is in both "Light Armor" and "Leather Armor").
  def change
    create_table :collections do |t|
      t.citext :name, null: false, index: { unique: true }
      t.text :description
      t.timestamps
    end

    create_table :collection_items do |t|
      t.references :collection, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :item, null: false, foreign_key: { on_delete: :cascade }, type: :integer
      t.timestamps
    end
    add_index :collection_items, [ :collection_id, :item_id ], unique: true

    create_table :collection_links do |t|
      t.references :parent, null: false, foreign_key: { to_table: :collections, on_delete: :cascade }, index: false
      t.references :child, null: false, foreign_key: { to_table: :collections, on_delete: :cascade }
      t.timestamps
    end
    add_index :collection_links, [ :parent_id, :child_id ], unique: true
  end
end
