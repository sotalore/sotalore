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
                plain " stand for anything that qualifies (like Crafted Chest Armor), often what an "
                plain "upgrade or modification recipe can be used on. A category may list some "
                plain "examples, but not necessarily all of them."
              end
            end
          end
        end
      end
    end

    by_kind = @items.group_by(&:kind)

    member_tiles("Groups", by_kind['group'])
    open_kind_list("Archetypes", by_kind['archetype'])
    open_kind_list("Categories", by_kind['category']&.reject { _1.members.any? })
    member_tiles("Categories with Examples", by_kind['category']&.select { _1.members.any? },
                 prefix: "e.g.")

    paginate @items
  end

  private

  def member_tiles(title, items, prefix: nil)
    return if items.blank?

    h2(class: "text-xl font-bold mx-2 mt-4") { title }
    div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3") do
      items.each do |item|
        tile do
          tile_heading(view_context.link_to(item.name, item))

          tile_body do
            p(class: "text-sm text-grey-600 dark:text-grey-300") { prefix } if prefix
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

  def open_kind_list(title, items)
    return if items.blank?

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
