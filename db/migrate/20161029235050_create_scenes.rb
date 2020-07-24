class CreateScenes < ActiveRecord::Migration[5.0]
  def change
    create_table :scenes do |t|
      t.string     :name
      t.integer    :level_id
      t.integer    :scene_type_id
      t.integer    :region_id
      t.integer    :parent_id
      t.integer    :sota_map_id, index: { unique: true }
      t.integer    :sota_map_parent_poi_id, index: { unique: true }

      t.timestamps
    end
  end
end
