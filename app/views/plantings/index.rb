# frozen_string_literal: true

class Views::Plantings::Index < Views::Base

  SEED_PRICE_TO_SPEED = {
    (0..15)    => 'Quick (24 hours)',
    (16..29)   => 'Medium (48 hours)',
    (30..1000) => 'Slow (72 hours)',
    nil        => 'Unknown'
  }

  def initialize(plantings:, planting: nil)
    @plantings = plantings
    @planting = planting
  end

  def view_template
    div(class: "grid grid-cols-3") do
      div(class: "col-span-3 lg:col-span-1") do
        tile_with_heading("Add a new planting") do
          sl_form_for(@planting || Planting.with_defaults) do |f|
            raw f.select(:seed_id, seeds_grouped_by_speed_options, include_blank: true)
            raw f.select(:location_type, Planting.location_types.keys, label: "Location Type")
            raw f.text_field(:planted_at, hint: "When did you plant?")
            raw f.text_area(:notes, placeholder: "Just something you need to remember")
            raw f.actions { f.submit }
          end
        end
      end

      if @plantings.any?
        div(class: "col-span-3 lg:col-span-2") do
          @plantings.each do |planting|
            render Components::Plantings::Card.new(planting: planting)
          end
        end
      end
    end
  end

  private

  def seeds_grouped_by_speed
    Item.use_is_seed.order(:price, :name)
      .group_by { |s| SEED_PRICE_TO_SPEED[SEED_PRICE_TO_SPEED.keys.find { |k| k === s.price }] }
      .sort_by { |k,v| SEED_PRICE_TO_SPEED.values.index(k) }
  end

  def seeds_grouped_by_speed_options
    seeds_grouped_by_speed.map do |grouping, seeds|
      [ grouping, seeds.map { |s| [ s.name, s.id ] } ]
    end
  end

end
