class AddTypeToItems < ActiveRecord::Migration[5.1]
  def change
    add_column :items, :type, :string, default: 'Item', null: false
    add_column :items, :type_data, :jsonb, default: {}, null: false
    reversible do |dir|
      dir.up {
        execute "update items set type = 'Seed' where use = #{Item.uses['seed']}"
      }
    end
  end
end
