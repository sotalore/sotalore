class AddDefaultToAvatar < ActiveRecord::Migration[6.1]
  def change
    add_column :avatars, :is_default, :boolean, null: false, default: false
  end
end
