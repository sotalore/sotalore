# frozen_string_literal: true

# Preview of what a template recipe implies (see TemplateExpansion): the
# concrete item, group membership, and recipe for each member of the group
# it takes. Anything missing is ticked to be created.
class Views::Recipes::Variants < Views::Base

  def initialize(recipe:, expansion:)
    @recipe = recipe
    @expansion = expansion
  end

  def view_template
    page_title("Variants of #{@recipe.name}")

    tile do
      tile_heading("Variants of #{@recipe.name}") { default_button_to("Back", recipe_path(@recipe)) }
      tile_body do
        if @expansion.valid?
          intro
          form_for_variants
        else
          notice_warning(@expansion.error)
        end
      end
    end
  end

  private

  def intro
    div(class: "Callout Callout-primary max-w-prose mb-2") do
      p do
        plain "For each member of "
        link_to(@expansion.ingredient_group.name, @expansion.ingredient_group)
        plain ", this makes the item, the membership in "
        plain @expansion.variants.first&.names&.keys&.map(&:name)&.to_sentence || "the result group"
        plain ", and a copy of this recipe using that member. Untick any the game doesn't have. "
        plain "Basic materials default to proficiency 1 and re-teachable, others to this recipe's "
        plain "proficiency and not teachable; change either per row. Anything that already exists is left alone."
      end
    end
  end

  def form_for_variants
    form(action: variants_recipe_path(@recipe), method: "post") do
      input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
      table(class: "table-auto text-sm") do
        thead do
          tr(class: "border-b-2 border-grey-300 dark:border-grey-600") do
            th(class: "pr-4 text-left") { "Create" }
            th(class: "pr-4 text-left") { "Member" }
            th(class: "pr-4 text-left") { "Item" }
            th(class: "pr-4 text-left") { "Recipe" }
            th(class: "pr-4 text-left") { "Proficiency" }
            th(class: "pr-4 text-left") { "Teachable" }
          end
        end
        tbody { @expansion.variants.each { variant_row(_1) } }
      end
      div(class: "mt-2") { button(type: "submit", class: "Button Button--default") { "Generate" } }
    end
  end

  def variant_row(variant)
    tr(class: "align-top border-t border-parchment-300 dark:border-grey-700") do
      td(class: "pr-4") do
        if variant.underivable?
          plain "-"
        elsif variant.complete?
          plain "done"
        else
          input(type: "checkbox", name: "member_ids[]", value: variant.member.id,
                checked: !variant.complete?, aria: { label: "Create #{variant.recipe_name}" })
        end
      end
      td(class: "pr-4") { link_to(variant.member.name, variant.member) }
      if variant.underivable?
        td(colspan: 4, class: "text-red-600") { "Can't work out a name from #{variant.member.name}." }
      else
        td(class: "pr-4") { variant.items.each { |name, item| existing_or_new(name, item) } }
        td(class: "pr-4") { existing_or_new(variant.recipe_name, variant.recipe) }
        recipe_settings(variant)
      end
    end
  end

  # Editable only for recipes still to be made; what an existing one has is
  # shown as it is.
  def recipe_settings(variant)
    if variant.recipe
      td(class: "pr-4") { plain variant.recipe.proficiency.to_s }
      td(class: "pr-4") { plain variant.recipe.teachable.to_s.humanize }
      return
    end

    td(class: "pr-4") do
      input(type: "number", min: 1, value: variant.proficiency, class: "field-input w-20",
            name: "variants[#{variant.member.id}][proficiency]",
            aria: { label: "Proficiency for #{variant.recipe_name}" })
    end
    td(class: "pr-4") do
      select(name: "variants[#{variant.member.id}][teachable]", class: "field-input",
             aria: { label: "Teachable for #{variant.recipe_name}" }) do
        option(value: "") { "" }
        Recipe.teachables.each_key do |key|
          option(value: key, selected: key == variant.teachable) { I18n.t(key, scope: [ :helpers, :label, :recipe, :teachables ]) }
        end
      end
    end
  end

  def existing_or_new(name, record)
    div do
      if record
        link_to(name, record)
      else
        plain name
        em(class: "text-grey-500") { " (new)" }
      end
    end
  end

end
