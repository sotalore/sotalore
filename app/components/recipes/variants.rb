# frozen_string_literal: true

# Explains what kind of recipe this is (see Recipe::KINDS): a template
# ("Dagger Blade") with the concrete recipes making its group's members
# ("Iron Dagger Blade", ...); an archetype recipe ("Dagger"), whose result
# depends on the ingredients; a modification; or, for a concrete recipe, the
# groups and templates its result belongs to.
class Components::Recipes::Variants < Components::Base

  def initialize(recipe:)
    @recipe = recipe
  end

  def view_template
    return unless @recipe.is_a?(Recipe)

    case @recipe.kind
    when 'modification' then modification_callout
    when 'template'     then template_section
    when 'archetype'    then archetype_callout
    else concrete_section
    end
  end

  private

  def modification_callout
    div(class: "Callout Callout-primary my-2") do
      p do
        plain "This modifies "
        item_links(@recipe.modified_items)
        plain ": what you put in is what you get back, changed."
      end
    end
  end

  def archetype_callout
    made = @recipe.results.map(&:item).select(&:abstract?)
    groups = @recipe.ingredients.map(&:item).select(&:group?)
    div(class: "Callout Callout-primary my-2") do
      p do
        plain "This makes "
        item_links(made)
        plain ", which stands for a kind of item. Which one you get depends on "
        if groups.any?
          plain "which "
          groups.each_with_index do |group, i|
            plain " and " if i.positive?
            link_to(group.name, group)
          end
          plain " you use."
        else
          plain "the ingredients used."
        end
      end
    end
  end

  def template_section
    groups = @recipe.results.map(&:item).select(&:group?)
    variants = @recipe.variants.active.includes(ingredients: :item, results: :item).by_name.to_a

    template_callout(groups)
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

  def template_callout(groups)
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
  end

  def item_links(items)
    items.each_with_index do |item, i|
      plain " or " if i.positive?
      plain article_for(item.name)
      whitespace
      link_to(item.name, item)
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
