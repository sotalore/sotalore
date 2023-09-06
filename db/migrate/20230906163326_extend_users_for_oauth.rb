# frozen_string_literal: true

class ExtendUsersForOauth < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :provider, :string, null: false, default: 'email'
    add_column :users, :uid, :string
  end
end
