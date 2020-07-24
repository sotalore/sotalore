class AddLevelPlusToScenes < ActiveRecord::Migration[5.2]
  def change
    add_column :scenes, :level_plus, :boolean, null: false, default: false
  end
end
