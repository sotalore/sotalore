class Result < ApplicationRecord
  belongs_to :recipe, inverse_of: :results, counter_cache: true
  belongs_to :item, inverse_of: :results, counter_cache: true

  delegate :name,
           to: :item, allow_nil: true

  delegate :fuel_cost,
           to: :recipe, allow_nil: true

  def to_s
    "#{count} #{name.pluralize(count)}"
  end
end
