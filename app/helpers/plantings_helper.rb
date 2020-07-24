# frozen-string-literal: true

module PlantingsHelper

  SEED_PRICE_TO_SPEED = {
    (0..15)    => 'Quick (24 hours)',
    (16..29)   => 'Medium (48 hours)',
    (30..1000) => 'Slow (72 hours)',
    nil        => 'Unknown'
  }
  def seeds_grouped_by_speed
    Item.use_is_seed.order(:price, :name)
      .group_by { |s| SEED_PRICE_TO_SPEED[SEED_PRICE_TO_SPEED.keys.find { |k| k === s.price }] }
      .sort_by { |k,v| SEED_PRICE_TO_SPEED.values.index(k) }
  end

  def seeds_grouped_by_speed_options
    seeds_grouped_by_speed.map do |grouping, seeds|
      [ grouping, seeds.map { |s| [ s.name, s.id ] }]
    end
  end
end
