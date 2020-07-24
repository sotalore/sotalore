FactoryBot.define do
  factory(:recipe) do

    sequence(:name) { |i| "Item #{i}" }
    craft_skill { CraftSkill::WITH_RECIPES.sample }

    transient do
      with_ingredients { { build(:item) => 1 } }
      with_results     { { build(:item) => 1 } }
    end

    before(:create) do |recipe,evaluator|
      recipe.ingredients << evaluator.with_ingredients.map do |item, count|
        Ingredient.new(item: item, count: count, recipe: recipe)
      end
      recipe.results << evaluator.with_results.map do |item, count|
        Result.new(item: item, count: count, recipe: recipe)
      end
    end
  end
end
