# frozen_string_literal: true

class Views::Searches::Global < Views::Base

  def initialize(searches:)
    @searches = searches
  end

  def view_template
    @searches.each do |result|
      link_to(
        result.searchable.name,
        result.searchable,
        class: "block p-2 list-group-item hover:text-zinc-100 hover:bg-orange-900",
        role: "option"
      )
    end

    if @searches.empty?
      div(class: "block p-2 list-group-item text-orange-900", role: "option") { "No results found" }
    end
  end

end
