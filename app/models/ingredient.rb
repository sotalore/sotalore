class Ingredient < ApplicationRecord
  belongs_to :recipe, inverse_of: :ingredients, counter_cache: true
  belongs_to :item, inverse_of: :ingredients, counter_cache: true

  validates :recipe, :item, presence: true

  delegate :name,
           to: :item, allow_nil: true

  def to_s
    "%5d %s" % [ count || 1, name]
  end

  def fuel_price
    # For now, just add up direct fuel costs.
    if item.use_is_fuel?
      (item.price || 0) * (count || 1)
    end
  end
end
