# frozen_string_literal: true

class AddParentToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :parent_type, :string
    add_column :posts, :parent_id, :integer

    add_index :posts, [:parent_type, :parent_id]
  end
end
