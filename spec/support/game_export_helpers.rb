# frozen_string_literal: true

# Builds recipe hashes shaped like the game recipe export plugin's output.
# +keys+ gives game keys by name (see sl-lua/EXPORT-FORMAT.md); an ingredient
# whose key is a "group:..." key becomes a group slot.
module GameExportHelpers
  def game_recipe_hash(name:, id: rand(1..2**31), category: 'Carpentry', level: 1,
                       ingredients: {}, results: { name => 1 }, tools: [], keys: {}, stats: {})
    ingredient = lambda do |n, q, tool|
      line = { 'name' => n, 'quantity' => q, 'optional' => false, 'tool' => tool }
      key = keys[n]
      if key&.start_with?('group:')
        line.merge('group' => true, 'groupKey' => key, 'choiceCount' => 0, 'choices' => [])
      elsif key
        line.merge('key' => key, 'stats' => [ { 'key' => 'weight', 'value' => 1 } ])
      else
        line
      end
    end
    {
      'id' => id,
      'name' => name,
      'category' => category,
      'categoryKey' => "Crafting_#{category}",
      'requiredLevel' => level,
      'refine' => false,
      'ingredients' =>
        ingredients.map { |n, q| ingredient.(n, q, false) } + tools.map { |n| ingredient.(n, 1, true) },
      'results' => results.map do |n, q|
        { 'name' => n, 'quantity' => q, 'key' => keys[n], 'stats' => stats[n] }.compact
      end,
    }
  end

  # +groups+ is [ { key:, name:, members: { key => name }, complete: } ].
  def game_export_json(*recipes, groups: [])
    {
      'apiVersion' => 26, 'count' => recipes.size, 'recipes' => recipes,
      'groups' => groups.map do |g|
        members = g.fetch(:members, {})
        { 'groupKey' => g[:key], 'name' => g[:name], 'choiceCount' => members.size,
          'memberCount' => members.size, 'complete' => g.fetch(:complete, true),
          'members' => members.map { |k, n| { 'key' => k, 'name' => n } } }
      end,
    }.to_json
  end

  # A made-up item key, the same for the same seed.
  def item_key(seed)
    "item:#{Digest::MD5.hexdigest(seed.to_s)}"
  end
end

RSpec.configure do |config|
  config.include GameExportHelpers
end
