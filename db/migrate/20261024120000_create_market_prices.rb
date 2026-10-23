class CreateMarketPrices < ActiveRecord::Migration[8.1]
  # What a user reckons players trade an item for, one each. Players sell
  # cheap things in bulk, so a price for one can be a fraction (garlic 1.2).
  def change
    create_table :market_prices do |t|
      t.references :user, null: false, foreign_key: true, type: :integer
      t.references :item, null: false, foreign_key: true, type: :integer, index: false
      t.decimal :price, precision: 12, scale: 2, null: false
      t.timestamps
    end
    add_index :market_prices, [ :item_id, :user_id ], unique: true
  end
end
