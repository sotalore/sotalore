# frozen_string_literal: true

class Views::Items::ByUse < Views::Items::Base

  def initialize(items:, use:)
    @items = items
    @use = use
  end

  def view_template
    page_title("Items: #{@use}")

    div(class: "grid grid-cols-1 md:grid-cols-2 items-center") do
      div { h1 { "Items: #{@use}".titleize } }
      div(class: "md:text-right text-sm mr-2") { render Views::Items::ItemNav.new }
    end

    div(class: "grid gap-1 grid-cols-1 md:grid-cols-2 lg:grid-cols-3") do
      @items.each do |item|
        tile do
          tile_heading(view_context.link_to(item.name, item))

          tile_body do
            if item.results_count > 0
              p { plain "Made from #{pluralize(item.results_count, 'recipe')}." }
            end

            if %w[ food pet-food ].include?(@use) && item.buff_slots_used.present?
              p do
                strong { "Buff Slots:" }
                plain " #{item.buff_slots_used}"
              end
            end

            if item.effects.present?
              h4 { "Effects" }
              formatted_body(item.effects)
            end

            if @use == "artifact" && item.salvage_as_source_count > 0
              h4 { "Salvages to:" }
              ul do
                item.salvages_to.each do |i|
                  li { link_to(i, i) }
                end
              end
            end
          end
        end
      end
    end

    phlex_paginate @items
  end

end
