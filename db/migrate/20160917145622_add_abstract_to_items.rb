class AddAbstractToItems < ActiveRecord::Migration[5.0]
  def change
    add_column :items, :abstract, :boolean, null: false, default: false
    add_column :items, :instance_id, :integer, foreign_key: { to_table: :items }
  end
end
