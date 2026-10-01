# frozen_string_literal: true

class Views::Recipes::Show < Views::Base

  def initialize(recipe:)
    @recipe = recipe
  end

  include Phlex::Rails::Helpers::ButtonTo

  def view_template
    page_title(@recipe.name)

    if @recipe.respond_to?(:retired?) && @recipe.retired?
      notice_warning("This recipe is retired: it's no longer in the game's recipe list.")
    end

    div(class: "flex flex-wrap") do
      div(class: "min-w-md grow") do
        tile do
          tile_body do
            render Components::Recipes::Card.new(recipe: @recipe)
            render Components::Recipes::Variants.new(recipe: @recipe)
            div(class: "grow flex flex-row justify-end") { render Views::Verifications::Controls.new(@recipe) }
            render Components::Comments::Subject.new(subject: @recipe)
          end
        end
      end

      div(class: "max-w-sm") do
        render Components::Recipes::WorkList.new(recipe: @recipe, count: params.fetch(:count, 1).to_i)
      end
    end

    if policy(@recipe).destroy?
      div(class: "text-right m-2") do
        retire_button if @recipe.respond_to?(:retired?)
        whitespace
        destroy_button_to("Delete Recipe", @recipe)
      end
    end
  end

  private

  def retire_button
    if @recipe.retired?
      button_to("Unretire", unretire_adm_recipe_path(@recipe), method: :post,
                class: "Button Button--default", form: { class: "inline-block" })
    else
      button_to("Retire", retire_adm_recipe_path(@recipe), method: :post,
                class: "Button Button--warning",
                form: { class: "inline-block", data: { turbo_confirm: "Mark this recipe as no longer in the game?" } })
    end
  end

end
