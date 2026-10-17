# frozen_string_literal: true

# The plugin's item catalog: items seen in a character's bags, with what
# their tooltips say. Salvages gain the tooltip's quantity range and chance;
# game keys keep the rest of the tooltip (value, merchant price, flags,
# effects, text) for later use.
class CreateItemCatalogImports < ActiveRecord::Migration[8.1]
  def change
    change_table :item_salvages do |t|
      t.integer :min_count, limit: 2
      t.integer :max_count, limit: 2
      t.decimal :chance, precision: 5, scale: 2
      t.datetime :game_synced_at
    end

    change_table :item_game_keys do |t|
      t.jsonb :catalog
      t.datetime :catalog_seen_at
    end

    create_table :item_catalog_imports do |t|
      t.references :uploaded_by, foreign_key: { to_table: :users }, type: :integer
      t.string :filename
      t.integer :api_version
      t.string :plugin_version
      t.jsonb :payload, null: false, default: {}
      t.datetime :applied_at
      t.timestamps
    end
  end
end
