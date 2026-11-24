class CreateSceneNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :scene_notes do |t|
      t.references :scene, null: false, foreign_key: true, type: :integer
      t.references :user, null: false, foreign_key: true, type: :integer
      t.text :text, null: false
      t.datetime :recorded_at, null: false
      t.integer :duration
      t.string :transcriber
      t.string :client_id, null: false
      t.timestamps
    end
    add_index :scene_notes, [ :user_id, :client_id ], unique: true
    add_index :scene_notes, :created_at
  end
end
