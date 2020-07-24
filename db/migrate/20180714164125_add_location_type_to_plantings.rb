class AddLocationTypeToPlantings < ActiveRecord::Migration[5.2]
  def change
    add_column :plantings, :location_type, :integer, null: false, default: 0
  end
end
