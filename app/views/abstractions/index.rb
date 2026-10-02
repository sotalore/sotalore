# frozen_string_literal: true

class Views::Abstractions::Index < Views::Base

  def initialize(items:)
    @items = items
  end

  def view_template
    page_title("Items")

    tile do
      tile_heading("Abstract Items") do
        new_button_to("New Item", new_item_path) if policy(Item).edit?
      end

      tile_body do
        div(class: "row") do
          div(class: "col-xs-12") do
            div(class: "Callout Callout-primary") do
              p do
                plain "There are a lot of \"items\" that are not real, actual items. "
                plain "These items are referred to as "
                em { "Abstract Items" }
                plain " (or "
                em { "Abstractions" }
                plain ")."
              end
              p do
                plain "These Abstract Items will often appear in a recipe, where "
                plain "any number of items (of all similar \"type\") can be used to "
                plain "execute the recipe."
              end
              p do
                plain "E.g., if you are asked for a \"Metal Binding\" you could use "
                plain "an \"Iron Binding\" or a \"Copper Binding\" (or many others). "
                plain "However, you will never find an actual item in the game named "
                plain "a \"Metal Binding.\""
              end
              p do
                plain "There are three kinds: "
                strong { "groups" }
                plain " list exactly which items they stand for (like Metal Binding); "
                strong { "archetypes" }
                plain " are a kind of thing, where which one a recipe makes depends on the "
                plain "ingredients used (like a Dagger); and "
                strong { "categories" }
                plain " stand for anything that qualifies, usually what an upgrade "
                plain "or modification recipe can be used on."
              end
            end
          end
        end
      end
    end

    by_kind = @items.group_by(&:kind)

    if (groups = by_kind['group'])
      h2(class: "text-xl font-bold mx-2 mt-4") { "Groups" }
      div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3") do
        groups.each do |item|
          tile do
            tile_heading(view_context.link_to(item.name, item))

            tile_body do
              ul do
                item.members.each do |member|
                  li { link_to(member.name, member) }
                end
              end
            end
          end
        end
      end
    end

    open_kind_list("Archetypes", by_kind['archetype'])
    open_kind_list("Categories", by_kind['category'])

    paginate @items
  end

  private

  def open_kind_list(title, items)
    return unless items

    tile do
      tile_heading(title)
      tile_body do
        ul(class: "flex flex-row flex-wrap gap-x-4 gap-y-1") do
          items.each { |item| li { link_to(item.name, item) } }
        end
      end
    end
  end

end
