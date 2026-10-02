# frozen_string_literal: true

# A read-only view over one recipe from the in-game recipe export plugin,
# e.g.
#
#   {"id":741803257,"name":"Accordion","category":"Carpentry",
#    "categoryKey":"Crafting_Carpentry","requiredLevel":40,"refine":false,
#    "ingredients":[{"name":"Wooden Board","quantity":8,"optional":false,"tool":false}],
#    "results":[{"name":"Accordion","quantity":1}]}
class GameRecipe

  Line = Data.define(:name, :count, :tool) do
    def tool? = tool
  end

  CATEGORY_PREFIX = 'Crafting_'

  attr_reader :payload

  # Accepts either a full export ({"recipes": [...]}) or a single recipe
  # object, as a JSON string or already-parsed Hash. Returns
  # [ api_version, full_export?, [GameRecipe] ].
  def self.parse_export(json)
    data = json.is_a?(String) ? JSON.parse(json) : json
    if data.is_a?(Hash) && data.key?('recipes')
      [ data['apiVersion'], true, Array(data['recipes']).map { new(_1) } ]
    elsif data.is_a?(Hash) && data.key?('ingredients')
      [ nil, false, [ new(data) ] ]
    elsif data.is_a?(Array)
      [ nil, false, data.map { new(_1) } ]
    else
      raise ArgumentError, 'Not a recipe export: expected a "recipes" list or a single recipe'
    end
  end

  def initialize(payload)
    @payload = payload.to_h.stringify_keys
  end

  def game_id
    payload['id']
  end

  def name
    payload['name'].to_s.strip
  end

  def category_key
    payload['categoryKey'].to_s
  end

  # nil when the game category doesn't correspond to a site craft skill
  # (e.g. Crafting_ObsidianForge).
  def craft_skill
    key = category_key.delete_prefix(CATEGORY_PREFIX).underscore
    skill = CraftSkill.find(key)
    skill if skill&.has_recipes?
  end

  def proficiency
    payload['requiredLevel']
  end

  def refine?
    !!payload['refine']
  end

  def ingredients
    @ingredients ||= Array(payload['ingredients']).map do |i|
      Line.new(i['name'].to_s.strip, i['quantity'].to_i, !!i['tool'])
    end
  end

  def results
    @results ||= Array(payload['results']).map do |r|
      Line.new(r['name'].to_s.strip, r['quantity'].to_i, false)
    end
  end

  def item_names
    (ingredients + results).map(&:name).uniq
  end

  # Names of the results this recipe takes and gives back, no more of than it
  # takes: what a modification acts on (see Recipe::KINDS).
  def modified_names
    taken = ingredients.to_h { |line| [ line.name.downcase, line.count ] }
    results.select { |line| (count = taken[line.name.downcase]) && line.count <= count }.map(&:name)
  end

  def modification?
    modified_names.any?
  end

end
