# frozen_string_literal: true

class Views::Searches::Items < Views::Base

  def initialize(searches:)
    @searches = searches
  end

  def view_template
    @searches.each do |result|
      li(class: "autocomplete-suggestion", role: "option", data: { "autocomplete-value" => result.searchable.id }) do
        plain result.searchable.name
      end
    end
  end

end
