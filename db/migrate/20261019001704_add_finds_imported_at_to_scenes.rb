class AddFindsImportedAtToScenes < ActiveRecord::Migration[8.1]
  # When a finds import last recorded what can be found in a scene. Scenes
  # that already have finds get the last time one of them was seen.
  def up
    add_column :scenes, :finds_imported_at, :datetime

    execute <<~SQL
      UPDATE scenes SET finds_imported_at = seen.at
      FROM (
        SELECT scene_id, max(updated_at) AS at FROM (
          SELECT scene_id, updated_at FROM scene_finds
          UNION ALL SELECT scene_id, updated_at FROM scene_creatures
          UNION ALL SELECT scene_id, updated_at FROM scene_nodes
        ) links GROUP BY scene_id
      ) seen
      WHERE scenes.id = seen.scene_id
    SQL
  end

  def down
    remove_column :scenes, :finds_imported_at
  end
end
