class CreateItems < ActiveRecord::Migration[5.0]
  def change
    create_table :items do |t|
      t.string      :name
      t.integer     :use, null: false, default: 0
      t.boolean     :crafting_input, null: false, default: false
      t.integer     :source, null: false, default: 0
      t.integer     :price
      t.string      :gathering_skill
      t.timestamps
    end
  end
end
