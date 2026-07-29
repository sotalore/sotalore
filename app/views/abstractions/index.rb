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
                plain "Below are (most) all of the known Abstractions and corresponding "
                plain "items."
              end
            end
          end
        end
      end
    end

    div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3") do
      @items.each do |item|
        tile do
          tile_heading(view_context.link_to(item.name, item))

          tile_body do
            ul do
              item.instances.each do |instance|
                li { link_to(instance.name, instance) }
              end
            end
          end
        end
      end
    end

    paginate @items
  end

end
