# frozen_string_literal: true

class AddVerificationColumns < ActiveRecord::Migration[7.1]
  def change
    rename_column :recipes, :last_confirmed_at, :last_verified_at
    rename_column :recipes, :last_confirmed_by_id, :last_verified_by_id
    rename_column :items, :last_confirmed_at, :last_verified_at
    rename_column :items, :last_confirmed_by_id, :last_verified_by_id
  end
end
