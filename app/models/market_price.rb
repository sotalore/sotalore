# frozen_string_literal: true

# What a user reckons players trade one of an item for. Each user keeps
# their own, so crafters can price their work without everyone seeing the
# same numbers. Only concrete items have one.
class MarketPrice < ApplicationRecord
  belongs_to :user, inverse_of: :market_prices
  belongs_to :item, inverse_of: :market_prices

  validates :price, numericality: { greater_than: 0, less_than: 10**10 }
  validates :item_id, uniqueness: { scope: :user_id }
  validate  :item_is_concrete

  # The price without trailing zeros: "1.2", "6".
  def to_s
    price.to_s('F').delete_suffix('.0')
  end

  private

  def item_is_concrete
    errors.add(:item, 'must be a concrete item') if item&.abstract?
  end
end
