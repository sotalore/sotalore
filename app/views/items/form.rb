# frozen_string_literal: true

class Views::Items::Form < Views::Items::Base
  include Grav::Views::Forms::Base

  def initialize(item:)
    super(model: item, data: { controller: "item-form" })
  end

  def view_template
    super do
      div(class: "grid grid-cols-1 lg:grid-cols-2 gap-4") do
        div do
          text_field(:name, autofocus: true)

          select_field(:use, data: { "item-form-target": "useSelect", action: "item-form#change_use" }) do |select|
            select.options(Item.uses.keys, display: :to_s, value: :to_s)
          end

          field_set_tag("Seed Information", data: { "item-form-target": "useSpecific", "for-use": "seed" }) do
            number_field(:yield, min: 1)
          end

          field_set_tag("Food Information", data: { "item-form-target": "useSpecific", "for-use": "food,pet-food" }) do
            number_field(:buff_slots_used, min: 1, max: 3)
          end

          select_field(:source) do |select|
            select.options(Item.sources.keys, display: :to_s, value: :to_s)
          end

          div(class: "grid grid-cols-1 md:grid-cols-2 gap-4") do
            checkbox_field(:abstract)

            select_field(:instance_id) do |select|
              select.options(abstract_items_options,
                display: ->(pair) { pair[0] },
                value: ->(pair) { pair[1].to_s },
                include_blank: :blank)
            end
          end

          div(class: "grid grid-cols-1 md:grid-cols-2 gap-4") do
            number_field(:weight, step: "0.01")
            number_field(:price, min: 1)
          end

          select_field(:gathering_skill, value: model.gathering_skill&.key) do |select|
            select.options(CraftSkill.gathering, display: :name, value: :key, include_blank: :blank)
          end
        end

        div do
          text_area_field(:effects, optional: true)
          text_area_field(:notes, optional: true)

          form_actions { submit_button }
        end
      end
    end
  end

end
