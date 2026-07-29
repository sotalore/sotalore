# frozen_string_literal: true

class Views::Recipes::Show < Views::Base

  def initialize(recipe:)
    @recipe = recipe
  end

  def view_template
    page_title(@recipe.name)

    div(class: "flex flex-wrap") do
      div(class: "min-w-md grow") do
        tile do
          tile_body do
            render Components::Recipes::Card.new(recipe: @recipe)
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
        destroy_button_to("Delete Recipe", @recipe)
      end
    end
  end

end
