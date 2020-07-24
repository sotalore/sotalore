class CreatePlantings < ActiveRecord::Migration[5.0]
  def change
    create_table :plantings do |t|
      t.references :user, foreign_key: true, null: false
      t.integer    :seed_id, null: false
      t.boolean    :greenhouse, null: false, default: false
      t.timestamp  :planted_at
      t.text       :notes
      t.timestamps
    end
  end
end
