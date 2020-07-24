# frozen-literal-string: true

module RecipeKey
  extend ActiveSupport::Concern

  def generate_recipe_key
    return nil if craft_skill.blank?
    ingredients = Array(self.ingredients)
    return nil if ingredients.empty?
    [ craft_skill.to_param ]
      .concat(ingredients_sorted_for_key
               .map { |i| "#{i.item_id}:#{i.count}" })
      .join("-")
  end

  private
  def ingredients_sorted_for_key
    ingredients.sort_by(&:item_id)
  end
end
