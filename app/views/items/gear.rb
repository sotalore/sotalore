# frozen_string_literal: true

# Armor, shields and weapons by what the game's tooltips say they are (see
# GearType), with links that narrow the list by each facet.
class Views::Items::Gear < Views::Items::Base

  LABELS = { kind: "Kind", weight: "Weight", material: "Material", slot: "Slot", damage: "Damage" }.freeze

  # +gear+: { item => GearType }; +filters+: { facet => value } applied.
  def initialize(gear:, filters:)
    @gear = gear
    @filters = filters
  end

  def view_template
    page_title("Gear")

    tile do
      tile_heading("Gear") { render Views::Items::ItemNav.new }

      tile_body do
        p(class: "max-w-prose mb-2") do
          plain "Armor, shields and weapons, by what the game's tooltips call them (\"Leather Light Armor (Head)\", "
          plain "\"Longsword - Bladed\"). Only items someone has hovered with the game plugin are here, so it's "
          plain "mostly dropped and quest gear; crafted gear is in "
          link_to("Collections", collections_path)
          plain "."
        end
        facet_links
        if @gear.empty?
          p { em { "Nothing matches." } }
        else
          gear_table
        end
      end
    end
  end

  private

  def facet_links
    div(class: "my-3 space-y-1 text-sm") do
      GearType::FACETS.each do |facet, values|
        div(class: "flex flex-row flex-wrap gap-x-3") do
          span(class: "w-20 font-semibold") { LABELS.fetch(facet) }
          facet_link("any", facet, nil)
          values.each { facet_link(_1, facet, _1) }
        end
      end
    end
  end

  def facet_link(label, facet, value)
    if @filters[facet] == value
      strong { label }
    else
      a(href: gear_items_path(@filters.merge(facet => value).compact), class: "Link Link--primary") { label }
    end
  end

  def gear_table
    p(class: "text-sm mb-1") { pluralize(@gear.size, "item") }
    table(class: "w-full table-auto text-sm") do
      thead do
        tr(class: "border-b-2 border-grey-300 dark:border-grey-600") do
          th(class: "py-1 pr-4 text-left") { "Item" }
          th(class: "py-1 pr-4 text-left") { "The game calls it" }
        end
      end
      tbody do
        @gear.each do |item, type|
          tr(class: "border-t border-parchment-300 dark:border-grey-700") do
            td(class: "py-1 pr-4") do
              link_to(item.name, item)
              whitespace
              item_abstract_tag(item)
            end
            td(class: "py-1 pr-4") { plain type.line }
          end
        end
      end
    end
  end

end
