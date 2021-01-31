class CreateAvatars < ActiveRecord::Migration[6.1]
  def change
    create_table :avatars do |t|
      t.belongs_to :user, null: false, index: true, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
