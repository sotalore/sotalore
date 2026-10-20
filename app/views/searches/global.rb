# frozen_string_literal: true

# Results for the top-bar search. They're options rather than links: the
# autocomplete controller clicks a link option itself, so a click on one
# started two Turbo visits (and left the progress bar showing). The
# search controller visits an option's value instead.
class Views::Searches::Global < Views::Base

  def initialize(searches:)
    @searches = searches
  end

  def view_template
    @searches.each do |result|
      div(
        class: "block p-2 list-group-item hover:text-zinc-100 hover:bg-orange-900",
        role: "option",
        data: { autocomplete_value: polymorphic_path(result.searchable), autocomplete_label: result.searchable.name }
      ) { result.searchable.name }
    end

    if @searches.empty?
      div(class: "block p-2 list-group-item text-orange-900", role: "option", aria_disabled: "true") { "No results found" }
    end
  end

end
