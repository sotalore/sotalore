class AddUserKeyToComments < ActiveRecord::Migration[5.0]
  def change
    add_column :comments, :user_key, :string
    add_column :comments, :visible, :boolean, null: false, default: true
  end
end
