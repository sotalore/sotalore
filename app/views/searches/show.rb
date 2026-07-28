# frozen_string_literal: true

class Views::Searches::Show < Views::Base

  def initialize(searches:)
    @searches = searches
  end

  def view_template
    layout_main_content(size: :sm) do
      tile_with_heading("Search results") do
        @searches.each do |result|
          case result.searchable
          when Recipe
            p do
              plain "Recipe: "
              link_to(result.searchable.name, result.searchable)
            end
          when Item
            p do
              plain "Item: "
              link_to(result.searchable.name, result.searchable)
            end
          end
        end
      end
    end
  end

end
