# frozen_string_literal: true

# Relates template recipes (which make a group, e.g. "Dagger Blade") and the
# concrete recipes that make its members ("Iron Dagger Blade", ...).
class Components::Recipes::Variants < Components::Base

  def initialize(recipe:)
    @recipe = recipe
  end

  def view_template
    return unless @recipe.is_a?(Recipe)

    if @recipe.template?
      template_section
    else
      concrete_section
    end
  end

  private

  def template_section
    groups = @recipe.results.map(&:item).select(&:abstract?)
    variants = @recipe.variants.active.includes(ingredients: :item, results: :item).by_name.to_a

    div(class: "Callout Callout-primary my-2") do
      p do
        strong { "This is a template recipe." }
        plain " Nothing in the game is literally #{article(groups.map(&:name).to_sentence)}. "
        plain "It stands for any member of "
        groups.each_with_index do |group, i|
          plain " or " if i.positive?
          link_to(group.name, group)
        end
        plain ", each made by its own recipe."
      end
    end

    if variants.empty?
      p { em { "No recipes for the members of this group are known yet." } }
      return
    end

    h3(class: "font-bold mt-2") { "Recipes that make #{article(groups.map(&:name).to_sentence)}" }
    table(class: "table-auto text-sm") do
      variants.each do |variant|
        tr(class: "align-top border-t border-parchment-300 dark:border-grey-700") do
          td(class: "pr-4") { link_to(variant.name, variant, class: "Link Link--primary") }
          td do
            plain variant.ingredients.sort_by { _1.item }.map { |i| "#{i.count} #{i.name}" }.join(", ")
          end
        end
      end
    end
  end

  def concrete_section
    groups = @recipe.result_groups.to_a
    return if groups.empty?

    templates = @recipe.templates.includes(results: :item).to_a
    div(class: "Callout Callout-primary my-2") do
      plain "This makes "
      groups.each_with_index do |group, i|
        plain(i == groups.size - 1 ? " and " : ", ") if i.positive?
        plain article_for(group.name)
        whitespace
        link_to(group.name, group)
      end
      plain "."
      if templates.any?
        plain " See the general recipe: "
        templates.each_with_index do |template, i|
          plain ", " if i.positive?
          link_to(template.name, template)
        end
        plain "."
      end
    end
  end

  def article(phrase)
    "#{article_for(phrase)} #{phrase}"
  end

  def article_for(word)
    word.match?(/\A[aeiou]/i) ? "an" : "a"
  end
end
