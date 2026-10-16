# frozen_string_literal: true

# A read-only view over one recipe from the in-game recipe export plugin
# (see docs/EXPORT-FORMAT.md), e.g.
#
#   {"id":741803257,"name":"Accordion","category":"Carpentry",
#    "categoryKey":"Crafting_Carpentry","requiredLevel":40,"refine":false,
#    "ingredients":[{"name":"Wooden Board","quantity":8,"optional":false,"tool":false,
#                    "group":true,"groupKey":"group:7","choiceCount":7,"choices":[...]}],
#    "results":[{"name":"Accordion","quantity":1,"key":"item:...","stats":[...]}]}
#
# Older exports have no keys, groups or stats.
class GameRecipe

  # An ingredient or result. +key+ is the game's id for it (see ItemGameKey):
  # "item:..." for an item, or "group:..." for a slot taking any member of a
  # group, whose members' keys are +choice_keys+.
  Line = Data.define(:name, :count, :tool, :key, :group, :choice_count, :choice_keys, :stats) do
    def initialize(name:, count:, tool: false, key: nil, group: false, choice_count: nil,
                   choice_keys: [], stats: [])
      super
    end

    def tool? = tool
    def group? = group
  end

  # An export file: its recipes and top-level groups (see GameGroup). +list+
  # is whether it has a "recipes" list, which every export file does, whether
  # it holds every recipe ("Export all"), only new ones ("Export new") or one;
  # only the uploader can say it's full.
  Export = Data.define(:api_version, :list, :recipes, :groups) do
    def list? = list
  end

  CATEGORY_PREFIX = 'Crafting_'

  attr_reader :payload

  # Accepts either an export file ({"recipes": [...], "groups": [...]}) or a
  # single recipe object, as a JSON string or already-parsed Hash. Returns an
  # Export.
  def self.parse_export(json)
    data = json.is_a?(String) ? JSON.parse(json) : json
    if data.is_a?(Hash) && data.key?('recipes')
      Export.new(data['apiVersion'], true, Array(data['recipes']).map { new(_1) },
                 Array(data['groups']).map { GameGroup.new(_1) })
    elsif data.is_a?(Hash) && data.key?('ingredients')
      Export.new(nil, false, [ new(data) ], [])
    elsif data.is_a?(Array)
      Export.new(nil, false, data.map { new(_1) }, [])
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
      if i['group']
        choices = Array(i['choices'])
        Line.new(name: i['name'].to_s.strip, count: i['quantity'].to_i, tool: !!i['tool'],
                 key: i['groupKey'].presence, group: true, choice_count: i['choiceCount'],
                 choice_keys: choices.filter_map { _1['key'] })
      else
        Line.new(name: i['name'].to_s.strip, count: i['quantity'].to_i, tool: !!i['tool'],
                 key: i['key'].presence, stats: Array(i['stats']))
      end
    end
  end

  # What the recipe makes. Recipes that change an item (Reshape, Masterwork,
  # socketing, Enchantment) have no fixed result in the export; they give back
  # what goes in their first group slot ("Crafted Carpentry Equipable"), so
  # that's their result, which makes them modifications (see Recipe::KINDS).
  # Other recipes without a fixed result (casks) have none.
  def results
    @results ||=
      if fixed_results?
        Array(payload['results']).map do |r|
          Line.new(name: r['name'].to_s.strip, count: r['quantity'].to_i, key: r['key'].presence,
                   stats: Array(r['stats']))
        end
      elsif (target = modification_target)
        [ target.with(tool: false) ]
      else
        []
      end
  end

  def fixed_results?
    Array(payload['results']).any?
  end

  # The group slot a recipe without a fixed result changes, if any.
  def modification_target
    ingredients.find(&:group?) unless fixed_results?
  end

  def lines
    ingredients + results
  end

  # { item key => weight } for every item the recipe mentions, group slot
  # choices included. A weight is per item, whatever the quantity.
  def item_weights
    rows = Array(payload['results']).map { [ _1['key'], _1['stats'] ] }
    Array(payload['ingredients']).each do |i|
      if i['group']
        Array(i['choices']).each { rows << [ _1['key'], _1['stats'] ] }
      else
        rows << [ i['key'], i['stats'] ]
      end
    end
    rows.each_with_object({}) do |(key, stats), weights|
      weight = Array(stats).find { _1['key'] == 'weight' }&.dig('value')
      weights[key] = weight if key && weight
    end
  end

  def item_names
    lines.map(&:name).uniq
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
