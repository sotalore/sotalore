# frozen_string_literal: true

# Replaces the abstract boolean with a kind:
#
#   concrete  - a real thing in the game
#   group     - a fixed set of concrete items the game calls by one name
#               ("Metal Ingot", "Dagger Blade")
#   archetype - a kind of thing a recipe makes, where which one depends on the
#               ingredients ("Dagger")
#   category  - anything meeting a rule, typically what a modification recipe
#               acts on ("Crafted Carpentry Equipable")
#
# Abstract items are classified by how they're used, first rule wins: has
# members -> group; an ingredient and result of the same recipe -> category;
# an ingredient -> group; only a result -> archetype; otherwise group. This is
# a best guess; the item review page (/adm/item_review) is for fixing it up.
#
# items.abstract is left in place (and ignored) until this is deployed.
class AddKindToItems < ActiveRecord::Migration[8.1]
  def up
    add_column :items, :kind, :integer, limit: 2, null: false, default: 0
    add_index :items, :kind

    execute <<~SQL
      UPDATE items SET kind = CASE
        WHEN EXISTS (SELECT 1 FROM item_memberships m WHERE m.group_id = items.id) THEN 1
        WHEN EXISTS (SELECT 1 FROM ingredients i
                     JOIN results r ON r.recipe_id = i.recipe_id AND r.item_id = i.item_id
                     WHERE i.item_id = items.id) THEN 3
        WHEN EXISTS (SELECT 1 FROM ingredients i WHERE i.item_id = items.id) THEN 1
        WHEN EXISTS (SELECT 1 FROM results r WHERE r.item_id = items.id) THEN 2
        ELSE 1
      END
      WHERE abstract
    SQL
  end

  def down
    execute 'UPDATE items SET abstract = (kind <> 0)'
    remove_column :items, :kind
  end
end
