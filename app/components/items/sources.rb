# frozen_string_literal: true

# On an item page: how to get it, from what the site records (see
# ItemSources). Where it's found in scenes is left to the finds tile.
class Components::Items::Sources < Components::Base

  MAX_SALVAGED = 8

  def initialize(sources:)
    @sources = sources
  end

  def view_template
    tile_with_heading("How to Get It") do
      kinds = @sources.kinds - [ :found ]
      if kinds.empty?
        p { em { "Nothing on the site says yet." } }
      else
        ul(class: "list-disc ml-5") { kinds.each { |kind| li { send(kind) } } }
      end
    end
  end

  private

  def crafted
    plain "Made by #{@sources.crafting_skills.map(&:name).to_sentence}"
  end

  def gathered
    plain "Gathered by #{@sources.gathering_skills.map(&:name).to_sentence}"
  end

  def salvaged
    items = @sources.salvaged_from
    plain "Salvaged from "
    items.first(MAX_SALVAGED).each_with_index do |item, i|
      plain ", " if i.positive?
      link_to(item.name, item)
    end
    plain " and #{items.size - MAX_SALVAGED} more" if items.size > MAX_SALVAGED
  end

  def bought
    plain "Sold by merchants"
  end
end
