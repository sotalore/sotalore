class ItemsGetNotes < ActiveRecord::Migration[5.1]
  def change
    add_column :items, :weight, :decimal, precision: 6, scale: 2
    add_column :items, :effects, :text
    add_column :items, :notes, :text
  end
end
