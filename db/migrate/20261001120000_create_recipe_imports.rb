# frozen_string_literal: true

# Supports syncing recipes from the in-game recipe export plugin:
#
# * recipes learn the game's stable recipe id, when they were last confirmed
#   against an export, and whether they've been retired from the game.
# * item_aliases remember old/alternate names for items so later exports
#   still match after an item is renamed to the game's name.
# * recipe_imports / recipe_import_entries hold an uploaded export and the
#   per-recipe analysis (match, diff, status) for admin review.
class CreateRecipeImports < ActiveRecord::Migration[8.1]
  def change
    change_table :recipes, bulk: true do |t|
      t.bigint :game_id
      t.datetime :game_synced_at
      t.datetime :retired_at
      t.index :game_id, unique: true
      t.index :retired_at
    end

    create_table :item_aliases do |t|
      t.citext :name, null: false
      t.references :item, null: false, foreign_key: true, type: :integer
      t.timestamps
      t.index :name, unique: true
    end

    create_table :recipe_imports do |t|
      t.references :uploaded_by, foreign_key: { to_table: :users }, type: :integer
      t.string :filename
      t.integer :api_version
      t.boolean :full_export, null: false, default: false
      t.integer :entries_count, null: false, default: 0
      t.datetime :analyzed_at
      t.timestamps
    end

    create_table :recipe_import_entries do |t|
      t.references :recipe_import, null: false, foreign_key: true
      t.bigint :game_id, null: false
      t.string :name, null: false
      t.jsonb :payload, null: false, default: {}
      t.references :recipe, foreign_key: { on_delete: :nullify }, type: :integer
      t.string :match_method
      t.boolean :manual_match, null: false, default: false
      t.integer :status, limit: 2, null: false, default: 0
      t.jsonb :diff, null: false, default: {}
      t.jsonb :problems, null: false, default: []
      t.datetime :applied_at
      t.timestamps
      t.index [ :recipe_import_id, :game_id ], unique: true
      t.index [ :recipe_import_id, :status ]
    end
  end
end
