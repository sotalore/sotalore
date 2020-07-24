class AddConfirmedToThings < ActiveRecord::Migration[5.0]
  def change
    add_column :items, :last_confirmed_by_id, :integer
    add_column :items, :last_confirmed_at, :timestamp
    add_column :recipes, :last_confirmed_by_id, :integer
    add_column :recipes, :last_confirmed_at, :timestamp

    add_foreign_key :items, :users, column: :last_confirmed_by_id
    add_foreign_key :recipes, :users, column: :last_confirmed_by_id
  end
end
