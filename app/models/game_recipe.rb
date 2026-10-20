# frozen_string_literal: true

# A read-only view over one recipe from the in-game recipe export plugin
# (see sl-lua/EXPORT-FORMAT.md), e.g.
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
  # group, whose members' keys are +choice_keys+. A +placeholder+ stands for
  # whatever item you choose, with no key of its own ("Worn Item" in Repair
  # Item, "Salvageable Item"): in files with keys, a plain ingredient without
  # one. Older files have no keys at all, so nothing in them is a placeholder.
  Line = Data.define(:name, :count, :tool, :key, :group, :choice_count, :choice_keys, :stats,
                     :placeholder) do
    def initialize(name:, count:, tool: false, key: nil, group: false, choice_count: nil,
                   choice_keys: [], stats: [], placeholder: false)
      super
    end

    def tool? = tool
    def group? = group
    def placeholder? = placeholder
  end

  # An export file: its recipes and top-level groups (see GameGroup). +list+
  # is whether it has a "recipes" list, which every export file does, whether
  # it holds every recipe ("Export all"), only new ones ("Export new") or one.
  # +scope+ is what the file says it holds ("all", "new" or "one"; plugin
  # 0.4+), or nil when it doesn't say; +plugin_version+ which plugin wrote it
  # (0.7.1+).
  Export = Data.define(:api_version, :list, :recipes, :groups, :scope, :plugin_version) do
    def list? = list
  end

  SCOPES = %w[ all new one ].freeze

  CATEGORY_PREFIX = 'Crafting_'

  # Game categories the site calls something else.
  CATEGORY_SKILLS = { 'farming' => 'agriculture' }.freeze

  attr_reader :payload

  # Accepts either an export file ({"recipes": [...], "groups": [...]}) or a
  # single recipe object, as a JSON string or already-parsed Hash. Returns an
  # Export.
  def self.parse_export(json)
    data = json.is_a?(String) ? JSON.parse(json) : json
    PluginFile.check_type!(data, 'recipes')
    if data.is_a?(Hash) && data.key?('recipes')
      Export.new(data['apiVersion'], true, Array(data['recipes']).map { new(_1) },
                 Array(data['groups']).map { GameGroup.new(_1) }, data['scope'].presence_in(SCOPES),
                 PluginFile.version(data))
    elsif data.is_a?(Hash) && data.key?('ingredients')
      Export.new(nil, false, [ new(data) ], [], nil, nil)
    elsif data.is_a?(Array)
      Export.new(nil, false, data.map { new(_1) }, [], nil, nil)
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
    skill = CraftSkill.find(CATEGORY_SKILLS.fetch(key, key))
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
        # Files with keys give every plain ingredient stats, even placeholders.
        Line.new(name: i['name'].to_s.strip, count: i['quantity'].to_i, tool: !!i['tool'],
                 key: i['key'].presence, stats: Array(i['stats']),
                 placeholder: i['key'].blank? && i.key?('stats'))
      end
    end
  end

  # What the recipe makes. Recipes that change an item (Reshape, Masterwork,
  # socketing, Enchantment, Repair, Salvage) have no fixed result in the
  # export; they give back the item they change (see #modification_target),
  # so that's their result, which makes them modifications (see
  # Recipe::KINDS). Other recipes without a fixed result (casks) have none.
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

  # What a recipe without a fixed result changes, if anything: its first
  # ingredient that stands for whatever item you choose, a group slot
  # ("Crafted Carpentry Equipable") or a placeholder ("Worn Item" in Repair
  # Item, which also takes a repair kit group).
  def modification_target
    ingredients.find { |line| line.group? || line.placeholder? } unless fixed_results?
  end

  def lines
    ingredients + results
  end

  # { item key => weight } for every item the recipe mentions, group slot
  # choices included. A weight is per item, whatever the quantity, and a
  # BigDecimal (see GameWeights.decimal).
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
      weights[key] = GameWeights.decimal(weight) if key && weight
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
