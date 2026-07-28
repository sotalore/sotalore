# frozen_string_literal: true

class Views::Recipes::FilterForm < Views::Base
  include Grav::Views::Forms::Base

  def initialize
    super(url: "#", style: :inline)
    simple_get_form!
  end

  def form_action
    recipes_path
  end

  def view_template
    super do
      text_field(:rq, skip_label: true, placeholder: "filter by name")

      select_field(:skill, skip_label: true) do |select|
        select.options(CraftSkill::WITH_RECIPES.map { |s| [ s.name, s.key ] }, display: :first, value: :last, include_blank: "-- any skill --")
      end

      number_field(:rsmin, skip_label: true, placeholder: "min skill")
      number_field(:rsmax, skip_label: true, placeholder: "max skill")

      div(class: "whitespace-nowrap") do
        submit_button("Filter", name: "")
        new_button_to("Add Recipe", new_recipe_path, class: "button middle secondary") if policy(Recipe).create?
        primary_button_to("Verify Recipes", recipe_verifications_path) if policy(:verification).index?
      end
    end
  end

end
