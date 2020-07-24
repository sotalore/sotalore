class AddPVPFlagToScenes < ActiveRecord::Migration[5.0]
  def change
    add_column :scenes, :pvp, :boolean, null: false, default: false
  end
end
