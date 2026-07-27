# frozen_string_literal: true

class Views::Items::Show < Views::Items::Base

  def initialize(item:, used_in:)
    @item = item
    @used_in = used_in
  end

  def view_template
    page_title(@item.name)

    tile do
      tile_heading(@item.name) do
        destroy_button_to("Delete", @item) if policy(@item).destroy?
        edit_button_to("Edit", edit_item_path(@item)) if policy(@item).edit?
      end

      tile_body do
        div do
          div(class: "Callout Callout-primary flex flex-row flex-wrap gap-x-1 gap-y-2") do
            item_use_tag(@item, large: true)
            item_use_specific_tags(@item, large: true)
            item_abstract_tag(@item, large: true)
            item_price_tag(@item, large: true)
            item_gathering_tag(@item, large: true)
            item_weight_tag(@item, large: true)
            div(class: "grow flex flex-row justify-end") { render Views::Verifications::Controls.new(@item) }
          end

          if @item.abstract
            div(class: "row") do
              div(class: "col-xs") do
                strong { "Abstraction of:" }
                plain " "
                raw safe(@item.instances.by_name.map { |i| view_context.link_to(i, i) }.to_sentence)
              end
            end
          elsif @item.instance_of
            div(class: "row") do
              div(class: "col-xs") do
                p do
                  strong { "Instance of:" }
                  plain " "
                  link_to(@item.instance_of, @item.instance_of)
                end
              end
            end
          end
        end
      end
    end

    div(class: "flex flex-col md:flex-row gap-2") do
      div(class: "basis-1_2 px-2") do
        div(class: "flex flex-col gapy-2") do
          div do
            if @item.craftable?
              if @item.abstract
                h3 { "Template #{'recipe'.pluralize(@item.recipes.length)} to craft abstract item..." }
              else
                h3 { "Crafted from #{pluralize(@item.recipes.length, 'Recipe')}..." }
              end
              raw view_context.render(partial: "recipes/recipe", collection: @item.recipes)

              if policy(Recipe).new?
                div(class: "text-right") { link_to("add another", new_recipe_path(item_id: @item.id)) }
              end
            else
              p(class: "text-center") do
                em { "no recipes make this." }
                if policy(Recipe).new?
                  plain " "
                  link_to("add one", new_recipe_path(item_id: @item.id))
                end
              end
            end
          end

          div do
            if @used_in.length.zero?
              div(class: "text-center") { em { "no recipes use this item." } }
            else
              h3 { plain "Used in #{pluralize(@used_in.total_count, 'Recipe')}:" }
              p do
                raw safe(@used_in.map { |recipe| view_context.link_to(recipe.name, recipe) }.to_sentence)
                phlex_paginate(@used_in)
              end
            end
          end
        end
      end

      div(class: "basis-1_2") do
        div(class: "flex flex-col gap-2") do
          tile_with_heading("Effects") { formatted_body(@item.effects) } if @item.effects
          tile_with_heading("Notes") { formatted_body(@item.notes) } if @item.notes

          tile_with_heading("Salvage") do
            if @item.salvage_as_result_count > 0
              p { strong { "Potentially obtain this item by salvaging:" } }
              ul do
                @item.item_salvages_as_result.each do |item_salvage|
                  li do
                    link_to(item_salvage.salvage_from, item_salvage.salvage_from)
                    destroy_icon_to(item_salvage, size: :small) if policy(:item_salvage).destroy?
                  end
                end
              end
            end

            if @item.salvage_as_source_count > 0
              p { strong { "Salvage this item to potentially get:" } }
              ul do
                @item.item_salvages_as_source.each do |item_salvage|
                  li do
                    link_to(item_salvage.salvage_to, item_salvage.salvage_to)
                    destroy_icon_to(item_salvage, size: :small) if policy(:item_salvage).destroy?
                  end
                end
              end
            end

            if (@item.salvage_as_result_count + @item.salvage_as_source_count) == 0
              p { "No salvage info" }
            end

            if policy(:item_salvage).create?
              sl_form_for(ItemSalvage.new) do |f|
                raw f.error_messages
                raw f.hidden_field(:salvage_from_id, value: @item.id)
                div(data: { controller: "autocomplete", "autocomplete-url-value": search_items_path }) do
                  raw f.text_field(:salvage_to_name, label: "this salvages to...", data: { "autocomplete-target": "input" })
                  raw f.hidden_field(:salvage_to_id, data: { "autocomplete-target": "hidden" })
                  ul(class: "autocomplete-suggestions", data: { "autocomplete-target": "results" })
                end
                raw f.submit("Add")
              end
            end
          end
        end
      end
    end

    tile do
      tile_body { render_comments_for(@item) }
    end
  end

end
