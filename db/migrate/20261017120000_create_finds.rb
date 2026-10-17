# frozen_string_literal: true

# Where things can be found in the game, from the plugin's finds file:
# which items turn up in which scene, which creatures live there, which
# gathering nodes are there, and what field dressing a creature or
# harvesting a node gives. Presence only: a row says "can be found here",
# not how often. finds_imports keeps each uploaded file for review.
class CreateFinds < ActiveRecord::Migration[8.1]
  def change
    add_column :scenes, :game_name, :string
    add_index :scenes, :game_name, unique: true

    create_table :creatures do |t|
      t.citext :name, null: false, index: { unique: true }
      t.text :notes
      t.timestamps
    end

    create_table :gathering_nodes do |t|
      t.citext :name, null: false, index: { unique: true }
      t.text :notes
      t.timestamps
    end

    create_table :scene_finds do |t|
      t.references :scene, null: false, foreign_key: true, type: :integer, index: false
      t.references :item, null: false, foreign_key: true, type: :integer
      t.timestamps
    end
    add_index :scene_finds, [ :scene_id, :item_id ], unique: true

    create_table :scene_creatures do |t|
      t.references :scene, null: false, foreign_key: true, type: :integer, index: false
      t.references :creature, null: false, foreign_key: true
      t.integer :level_min, limit: 2
      t.integer :level_max, limit: 2
      t.timestamps
    end
    add_index :scene_creatures, [ :scene_id, :creature_id ], unique: true

    create_table :scene_nodes do |t|
      t.references :scene, null: false, foreign_key: true, type: :integer, index: false
      t.references :gathering_node, null: false, foreign_key: true
      t.timestamps
    end
    add_index :scene_nodes, [ :scene_id, :gathering_node_id ], unique: true

    # What field dressing a creature, or harvesting a node, gives.
    create_table :harvest_yields do |t|
      t.references :source, polymorphic: true, null: false, index: false
      t.references :item, null: false, foreign_key: true, type: :integer
      t.timestamps
    end
    add_index :harvest_yields, [ :source_type, :source_id, :item_id ], unique: true

    create_table :finds_imports do |t|
      t.references :uploaded_by, foreign_key: { to_table: :users }, type: :integer
      t.string :filename
      t.integer :api_version
      t.string :plugin_version
      t.jsonb :payload, null: false, default: {}
      t.datetime :applied_at
      t.timestamps
    end
  end
end
