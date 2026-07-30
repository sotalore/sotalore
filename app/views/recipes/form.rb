# frozen_string_literal: true

class Views::Recipes::Form < Views::Base
  include Grav::Views::Forms::Base

  register_value_helper :t
  register_value_helper :search_items_path

  def initialize(recipe:)
    @recipe_form = recipe
    @recipe_form.setup_for_view
    super(model: @recipe_form)
  end

  def view_template
    super do
      error_messages

      div(class: "grid grid-cols-2 gap-2") do
        div do
          text_field(:name, autofocus: true)

          div(class: "grid grid-cols-12 gap-2") do
            div(class: "col-span-5") do
              select_field(:craft_skill) do |select|
                select.options(craft_skills_for_recipe_options, display: :first, value: :last, include_blank: :blank)
              end
            end
            div(class: "col-span-3") { number_field(:proficiency) }
            div(class: "col-span-4") do
              select_field(:teachable) do |select|
                select.options(teachable_options, display: :first, value: :last, include_blank: :blank)
              end
            end
          end

          results_rows
        end

        div { ingredients_rows }
      end

      form_actions do
        cancel_button
        submit_button
      end
    end
  end

  private

  def craft_skills_for_recipe_options
    CraftSkill::WITH_RECIPES.map do |cs|
      name = "#{cs.name} (#{cs.primary_tool})"
      [ name, cs.key ]
    end
  end

  def teachable_options
    Recipe.teachables.keys.map { |k| [ t(k, scope: [ :helpers, :label, :recipe, :teachables ]), k ] }
  end

  def results_rows
    @recipe_form.results.each_with_index do |result, i|
      index = i + 1
      name_tabindex = index == 1 ? 0 : 100 + index
      count_tabindex = index == 1 ? 0 : 101 + index
      nested_item_row(:results, result, index: i, label_text: "Output #{index}",
        name_tabindex: name_tabindex, count_tabindex: count_tabindex)
    end
  end

  def ingredients_rows
    @recipe_form.ingredients.each_with_index do |ingredient, i|
      index = i + 1
      nested_item_row(:ingredients, ingredient, index: i, label_text: "Ingredient #{index}")
    end
  end

  # Grav's field helpers assume a flat top-level attribute, so Rails'
  # nested-attributes param naming (recipe[results_attributes][N][x]) is
  # built by hand here rather than through the normal field()/text_field().
  def nested_item_row(association, record, index:, label_text:, name_tabindex: nil, count_tabindex: nil)
    param_base = "recipe[#{association}_attributes][#{index}]"
    id_base = "recipe_#{association}_attributes_#{index}"

    div(class: "grid grid-cols-12 gap-2") do
      div(class: "col-span-10", data: { controller: "autocomplete", "autocomplete-url-value": search_items_path }) do
        div(class: "field-container") do
          label(for: "#{id_base}_name") { label_text }
          input(type: "text", class: "field-input", id: "#{id_base}_name", name: "#{param_base}[name]",
            value: record.name, tabindex: name_tabindex, data: { "autocomplete-target": "input" })
        end
        input(type: "hidden", id: "#{id_base}_item_id", name: "#{param_base}[item_id]",
          value: record.item_id, data: { "autocomplete-target": "hidden" })
        ul(class: "autocomplete-suggestions", data: { "autocomplete-target": "results" })
      end
      div(class: "col-span-2") do
        div(class: "field-container") do
          label(for: "#{id_base}_count") { "Count" }
          input(type: "text", class: "field-input", id: "#{id_base}_count", name: "#{param_base}[count]",
            value: record.count, tabindex: count_tabindex)
        end
      end
    end
  end

end
