# frozen_string_literal: true

class ItemNameShouldBeCitext < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'citext'
    change_column :items, :name, :citext
  end
end
