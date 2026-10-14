# frozen_string_literal: true

# The game's own ids for items, from recipe exports: "item:<32 hex>" for
# items and "group:<n>" for the slots that take any member of a group. One
# site item can have several (the game has same-named variants, and two
# groups can stand for the same set), but a key belongs to one item.
#
# recipe_imports.groups_payload keeps an export's top-level "groups" list.
class CreateItemGameKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :item_game_keys do |t|
      t.references :item, null: false, foreign_key: true, type: :integer
      t.string :key, null: false, index: { unique: true }
      t.string :name, null: false
      t.jsonb :stats
      t.timestamps
    end

    add_column :recipe_imports, :groups_payload, :jsonb, null: false, default: []
  end
end
