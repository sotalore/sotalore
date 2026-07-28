# frozen_string_literal: true

class Views::Plantings::Index < Views::Base

  register_value_helper :seeds_grouped_by_speed_options

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

end
