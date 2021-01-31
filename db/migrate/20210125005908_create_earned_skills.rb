class CreateEarnedSkills < ActiveRecord::Migration[6.1]
  def change
    create_table :earned_skills do |t|
      t.belongs_to :avatar, null: false, index: true, foreign_key: true
      t.string :skill_key, null: false
      t.integer :current, limit: 2
      t.integer :target, limit: 2
      t.timestamps
    end
  end
end
