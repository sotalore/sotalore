class ClearMerchantPricesEnteredAsValues < ActiveRecord::Migration[8.1]
  # Before items had a value, it was often entered as the merchant price, which
  # was the only price there was. A merchant sells for more than it pays, so a
  # merchant price at or below the value is one of those: mostly gathered and
  # salvaged things (Animal Hide 10, gem fragments 1) merchants don't sell.
  # Each is recorded as a revision by the first root user, when there is one.
  def up
    author = User.where('roles @> ?', '{root}').order(:id).first
    Item.where('value > 0 AND merchant_price <= value').find_each do |item|
      old = item.merchant_price
      item.update_columns(merchant_price: nil, updated_at: Time.current)
      author && item.comments.create!(author: author, comment_type: 'revision',
                                      body: { changes: { merchant_price: [ old, nil ] } }.to_json)
    end
  end

  # The prices were wrong, so there's nothing to put back.
  def down
  end
end
