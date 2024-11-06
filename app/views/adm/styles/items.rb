# frozen_string_literal: true

class Views::Adm::Styles::Items < Views::Base
  def view_template
    div(class: 'max-w-2xl') do
      render Views::Adm::Styles::Menu.new

      render Components::Tile.new(heading: 'Old Items Tags') do |tile|
        div(class: 'py-2') do
          ItemsHelper::USES_FOR_RECIPES.each do |use|
            raw helpers.item_use_for_recipe_tag(Item.new(use: use))
          end
        end

        div(class: 'py-2') do
          helpers.item_price_tag(Item.new(price: 12))
        end

        div(class: 'py-2') do
          CraftSkill::ALL.select { |skill| skill.gathering? }.each do |skill|
            raw helpers.item_gathering_tag(Item.new(gathering_skill: skill))
          end
        end

        div(class: 'py-2') do
          raw helpers.item_abstract_tag(Item.new(abstract: true))
          raw helpers.item_weight_tag(Item.new(weight: 2.2))
        end

        div(class: 'py-2') do
          Item::ITEM_USES.keys.each do |use|
            raw helpers.item_use_tag(Item.new(use: use))
          end
        end

        div(class: 'py-2') do
          Item::ITEM_USES.keys.each do |use|
            raw helpers.item_use_tag(Item.new(use: use), large: true)
          end
        end

        div(class: 'py-2') do
          CraftSkill::ALL.select { |skill| skill.gathering? }.each do |skill|
            raw helpers.item_gathering_tag(Item.new(gathering_skill: skill))
          end
        end
        div(class: 'py-2') do
          CraftSkill::ALL.select { |skill| skill.gathering? }.each do |skill|
            raw helpers.item_gathering_tag(Item.new(gathering_skill: skill), large: true)
          end
        end
      end
    end
  end
end
