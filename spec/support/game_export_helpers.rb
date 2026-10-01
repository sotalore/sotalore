# frozen_string_literal: true

# Builds recipe hashes shaped like the game recipe export plugin's output.
module GameExportHelpers
  def game_recipe_hash(name:, id: rand(1..2**31), category: 'Carpentry', level: 1,
                       ingredients: {}, results: { name => 1 }, tools: [])
    {
      'id' => id,
      'name' => name,
      'category' => category,
      'categoryKey' => "Crafting_#{category}",
      'requiredLevel' => level,
      'refine' => false,
      'ingredients' =>
        ingredients.map { |n, q| { 'name' => n, 'quantity' => q, 'optional' => false, 'tool' => false } } +
        tools.map { |n| { 'name' => n, 'quantity' => 1, 'optional' => false, 'tool' => true } },
      'results' => results.map { |n, q| { 'name' => n, 'quantity' => q } },
    }
  end

  def game_export_json(*recipes)
    { 'apiVersion' => 26, 'count' => recipes.size, 'recipes' => recipes }.to_json
  end
end

RSpec.configure do |config|
  config.include GameExportHelpers
end
