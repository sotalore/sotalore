# frozen_string_literal: true

# items.abstract was replaced by items.kind, and items.instance_id by
# item_memberships; both have been ignored by the app since.
class RemoveSupersededItemColumns < ActiveRecord::Migration[8.1]
  def up
    remove_column :items, :abstract
    remove_column :items, :instance_id
  end

  def down
    add_column :items, :abstract, :boolean, null: false, default: false
    add_column :items, :instance_id, :integer
    execute 'UPDATE items SET abstract = (kind <> 0)'
  end
end
