# frozen_string_literal: true

class Components::Recipes::Card < Components::Recipes::Base
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::CurrentPage

  register_value_helper :t
  register_output_helper :user_recipe_button
  register_output_helper :edit_recipe_icon
  register_output_helper :view_icon_to
  register_output_helper :view_link_to
  register_output_helper :more_link_to
  register_output_helper :to_sentence

  def initialize(recipe:)
    @recipe = recipe
  end

  def view_template
    div(class: "Recipe p-0 mb-4 border border-parchment-950 bg-parchment-100") do
      header_row
      skill_row
      ingredients_section
    end
  end

  private

  def header_row
    div(class: "Recipe-name p-2 font-bold flex flex-row justify-between items-center border-b border-parchment-950") do
      div(class: "grow whitespace-nowrap overflow-hidden text-ellipsis") do
        user_recipe_button(@recipe)
        whitespace
        plain @recipe.name
      end
      div(class: "text-sm") do
        unless current_page?(@recipe)
          if policy(Recipe).new?
            view_icon_to(@recipe)
          else
            view_link_to("details", @recipe)
          end
          whitespace
        end
        edit_recipe_icon(@recipe)
      end
    end
  end

  def skill_row
    div(class: "p-1 flex flex-row items-start border-b border-dashed border-parchment-950 border-opacity-20") do
      image_tag("sota-icons/#{@recipe.craft_skill.icon_name}", class: "w-12")
      div(class: "grow") do
        skill_summary
        makes_line
      end
    end
  end

  def skill_summary
    div(class: "opacity-50") do
      plain @recipe.craft_skill.name.titleize
      whitespace
      if @recipe.proficiency
        plain "[#{@recipe.proficiency}]"
        whitespace
      end
      span(class: "text-sm") { "(#{@recipe.craft_skill.primary_tool})" }
      if @recipe.teachable.present?
        whitespace
        span(class: "italic") { t(@recipe.teachable, scope: [ :helpers, :label, :recipe, :teachables ], default: "") }
      end
    end
  end

  def makes_line
    div(class: "text-sm") do
      span(class: "opacity-75 italic") { "Makes" }
      whitespace
      fragments = @recipe.results.map do |result|
        capture do
          plain "#{result.count} "
          link_to(result.item.name.to_s.pluralize(result.count), result.item)
        end
      end
      if fragments.present?
        to_sentence(fragments)
      else
        em { "unknown" }
      end
    end
  end

  def ingredients_section
    div(class: "p-2") do
      span(class: "opacity-75 italic") { "Ingredients:" }
      @recipe.ingredients.eager_load(item: { recipes: :results }).each do |ingredient|
        ingredient_row(ingredient)
      end
    end
  end

  def ingredient_row(ingredient)
    ingredient_dom_id = dom_id(ingredient)
    item = ingredient.item

    div(class: "Recipe-ingredient", data: { controller: "more-link" }) do
      div(class: "Recipe-ingredientSummary flex flex-row items-center gap-1") do
        span(class: "inline-block text-right min-w-8") { ingredient.count.to_s }
        whitespace
        link_to(ingredient.name, item)
        whitespace
        item_use_for_recipe_tag(item)
        whitespace
        item_price_tag(item)
        whitespace
        item_gathering_tag(item)
        whitespace
        item_abstract_tag(item)

        item.recipes.each do |r|
          next if @recipe == r

          whitespace
          more_link_to(recipe_path(r), data: { action: "more-link#load", url: show_partial_recipe_path(r), more_id: dom_id(r, ingredient_dom_id) })
        end
      end
      div(class: "Recipe-ingredientSubDetail pl-4 -mr-1", data: { "more-link-target": "subDetail" })
    end
  end

end
