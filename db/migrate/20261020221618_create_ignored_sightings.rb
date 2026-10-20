class CreateIgnoredSightings < ActiveRecord::Migration[8.1]
  # Names a finds file lists as targeted in a scene but never fought (its
  # "seen" list) that aren't creatures there: NPCs, players, pets. Ignored
  # per scene, so later imports leave them out of review there.
  def change
    create_table :ignored_sightings do |t|
      t.references :scene, type: :integer, null: false, foreign_key: true, index: false
      t.citext :name, null: false
      t.timestamps
    end
    add_index :ignored_sightings, [ :scene_id, :name ], unique: true
  end
end
