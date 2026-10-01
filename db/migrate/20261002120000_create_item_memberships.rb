# frozen_string_literal: true

# Items can belong to many groups. The game names sets of items ("Metal
# Ingot", "Copper or Iron Ingot") and one concrete item can be in several of
# them, which the single items.instance_id parent couldn't represent.
#
# Existing instance_id links are copied over. The column itself is left in
# place (and ignored by Item) so code running during the deploy keeps working;
# drop it in a follow-up migration.
class CreateItemMemberships < ActiveRecord::Migration[8.1]
  def up
    create_table :item_memberships do |t|
      t.references :group, null: false, type: :integer, index: false,
                           foreign_key: { to_table: :items, on_delete: :cascade }
      t.references :member, null: false, type: :integer,
                            foreign_key: { to_table: :items, on_delete: :cascade }
      t.timestamps
      t.index [ :group_id, :member_id ], unique: true
    end

    execute <<~SQL
      INSERT INTO item_memberships (group_id, member_id, created_at, updated_at)
      SELECT instance_id, id, now(), now()
      FROM items
      WHERE instance_id IS NOT NULL AND instance_id <> id
    SQL
  end

  def down
    execute <<~SQL
      UPDATE items SET instance_id = m.group_id
      FROM (SELECT DISTINCT ON (member_id) member_id, group_id
            FROM item_memberships ORDER BY member_id, id) m
      WHERE items.id = m.member_id
    SQL
    drop_table :item_memberships
  end
end
