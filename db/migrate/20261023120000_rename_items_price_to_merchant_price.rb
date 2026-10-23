class RenameItemsPriceToMerchantPrice < ActiveRecord::Migration[8.1]
  # "Price" was always what a merchant charges, as distinct from the game's
  # "value" (what a merchant pays) and the player market price. Item revision
  # comments name the attribute they changed, so their history is renamed too.
  def up
    rename_column :items, :price, :merchant_price
    rename_revision_key 'price', 'merchant_price'
  end

  def down
    rename_column :items, :merchant_price, :price
    rename_revision_key 'merchant_price', 'price'
  end

  private

  def rename_revision_key(from, to)
    execute <<~SQL
      UPDATE comments
      SET body = jsonb_set(body::jsonb #- '{changes,#{from}}', '{changes,#{to}}', body::jsonb -> 'changes' -> '#{from}')::text
      WHERE comment_type = 1 AND subject_type = 'Item' AND body LIKE '%"#{from}"%'
        AND body::jsonb -> 'changes' ? '#{from}'
    SQL
  end
end
