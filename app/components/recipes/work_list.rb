# frozen_string_literal: true

class Components::Recipes::WorkList < Components::Recipes::Base

  def initialize(recipe:, count: 1)
    @recipe = recipe
    @count = count
  end

  def view_template
    tile_with_heading("Work List") do
      render Components::Recipes::WorkListForm.new(recipe: @recipe, count: @count)

      div(class: "pb-4") do
        list = @recipe.work_list(@count)
        ul do
          fuels_section(list) if list.fuels.any?
          tools_section(list) if list.tools.any?
          gathered_section(list) if list.gathered.any?
          components_section(list) if list.components.any?
          recipes_section(list)
        end
      end
    end
  end

  private

  def fuels_section(list)
    li { h4(class: "mb-0 mt-2 mx-0") { "Fuels" } }
    list.fuels.each do |item, count|
      li(class: "pl-4") do
        plain "#{count} #{item} "
        item_price_tag(item)
      end
    end
  end

  def tools_section(list)
    li { h4(class: "mb-0 mt-2 mx-0") { "Tools" } }
    list.tools.each do |item, _|
      li(class: "pl-4") { plain item.to_s }
    end
  end

  def gathered_section(list)
    li { h4(class: "mb-0 mt-2 mx-0") { "Gathered Materials" } }
    list.gathered.each do |item, count|
      li(class: "pl-4") do
        plain "#{count} #{item} "
        item_gathering_tag(item)
      end
    end
  end

  def components_section(list)
    li { h4(class: "mb-0 mt-2 mx-0") { "Other Components" } }
    list.components.each do |item, count|
      li(class: "pl-4") do
        plain "#{count} #{item} "
        item_price_tag(item)
      end
    end
  end

  def recipes_section(list)
    li { h4(class: "mb-0 mt-2 mx-0") { "Recipes to Execute" } }
    list.recipes.each do |recipe, count|
      li(class: "pl-4") do
        plain "#{count} #{recipe} "
        craft_skill_tag(recipe.craft_skill)
      end
    end
  end

end
