# frozen_string_literal: true

class Views::Items::Index < Views::Items::Base

  def initialize(items:)
    @items = items
  end

  def view_template
    page_title("Items")

    tile do
      tile_heading("Items") { render Views::Items::ItemNav.new }

      tile_body do
        phlex_paginate @items

        table(class: "Table") do
          thead do
            th { "Item Name" }
            th { }
            th { }
          end

          tbody do
            @items.each do |item|
              tr do
                td { link_to(item.name, item) }
                td do
                  item_use_tag(item)
                  item_price_tag(item)
                end
                td do
                  plain "Used in #{pluralize(item.ingredients_count, 'recipe')}." if item.ingredients_count > 0
                  plain "Made from #{pluralize(item.results_count, 'recipe')}." if item.results_count > 0
                end
              end
            end
          end
        end

        phlex_paginate @items
      end
    end
  end

end
