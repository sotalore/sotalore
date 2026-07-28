# frozen_string_literal: true

class Components::Recipes::WorkListForm < Components::Recipes::Base
  include Grav::Views::Forms::Base

  def initialize(recipe:, count:)
    @recipe = recipe
    @count = count
    super(url: "#", style: :inline)
    simple_get_form!
  end

  def form_action
    recipe_path(@recipe)
  end

  def view_template
    super do
      number_field(:count, value: @count, label: "Show Mats to make:", class: "Field-input--numeric")

      form_actions { submit_button("Go") }
    end
  end

end
