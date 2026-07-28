# frozen_string_literal: true

class Views::Recipes::Index < Views::Base

  def initialize(recipes:)
    @recipes = recipes
  end

  def view_template
    page_title("Recipes")

    tile do
      tile_body do
        render Views::Recipes::FilterForm.new
      end
    end

    tile do
      tile_body do
        phlex_paginate @recipes
        recipes_table
        phlex_paginate @recipes
      end
    end
  end

  private

  def recipes_table
    table(class: "Table") do
      thead do
        th { "Recipe Name" }
        th { "Skill" }
        th(class: "u-textRight") { "Proficiency" }
        th(class: "u-textRight") { "Ingredients" }
        th { "Produces Item(s)" }
      end

      tbody do
        @recipes.each do |recipe|
          tr do
            td { link_to(recipe.name, recipe) }
            td { recipe.craft_skill.to_s }
            td(class: "u-textRight") { recipe.proficiency.to_s }
            td(class: "u-textRight") { recipe.ingredients_count.to_s }
            td do
              recipe.results.each do |result|
                link_to(result.to_s, result.item)
              end
            end
          end
        end
      end
    end
  end

end
