# frozen_string_literal: true

# A read-only view over the plugin's item catalog (see sl-lua/EXPORT-FORMAT.md):
# items seen in a character's bags, each with its key, weight, gold value and,
# when the player hovered it with capture on, what its tooltip said, e.g.
#
#   {"apiVersion":40,"count":2,"items":[{"key":"item:...","name":"Cotton Cloth Leggings +2",
#     "weight":1,"value":25,"details":{"tool":false,"questItem":false,
#     "salvage":[{"name":"Fabric Scrap","min":4,"max":40,"chance":90.5}],
#     "yields":"Eternal Pattern: Cotton Cloth Leggings","text":"..."}}]}
#
# A crafted item shares its key with the base item, and its tooltip gives only
# the salvage list (the same for the kind of item).
class GameCatalog

  # A salvage component: how many of it come back, and the percentage chance.
  Salvage = Data.define(:name, :min, :max, :chance)

  Entry = Data.define(:key, :name, :weight, :value, :details) do
    def details? = !details.nil?

    # A crafted item ("Bronze Dagger +11"): one of a kind, sharing the base
    # item's key, with a salvage list that depends on its materials. Only the
    # tooltip's "Crafted by" says so: a "+N" name doesn't (creatures drop +N
    # weapons that are items in their own right), and the API's own field
    # for it is unreliable.
    def crafted? = !!details&.dig('crafted')
    def tool? = !!details&.dig('tool')
    def quest_item? = !!details&.dig('questItem')

    # What salvaging gives: the tooltip's components, and what it "yields"
    # (an Eternal Pattern, say) as one of them. A crafted item's pattern is
    # its own (a reshaped one's especially), so only its components count.
    def salvage
      components = Array(details&.dig('salvage')).filter_map do |c|
        name = GameFinds.clean_name(c['name'])
        Salvage.new(name, c['min']&.to_i, c['max']&.to_i, c['chance']) if name.present?
      end
      yields = GameFinds.clean_name(details&.dig('yields'))
      components << Salvage.new(yields, 1, 1, nil) if yields.present? && !crafted?
      components.uniq { _1.name.downcase }
    end

    def merchant_pays
      details&.dig('merchantPays')&.values_at('min', 'max')
    end
  end

  attr_reader :api_version, :plugin_version, :scope, :entries

  # Per-item weights, values and merchant prices are only right from here.
  MINIMUM_VERSION = Gem::Version.new('0.8.1')
  # From this game API on, bag weights and values are already one item's, and
  # plugins before FIXED_VERSION divided them by the stack size again: far
  # too small, and different for every stack size.
  PER_ITEM_API = 41
  FIXED_VERSION = Gem::Version.new('0.11.1')

  # Raises ArgumentError for anything that isn't an item catalog, or (unless
  # +require_version+ is false, for one already stored) is one whose weights
  # and prices can't be trusted (see .problem).
  def self.parse(json, require_version: true)
    data = json.is_a?(String) ? JSON.parse(json) : json
    PluginFile.check_type!(data, 'items')
    if require_version && (problem = problem(data.is_a?(Hash) && data['apiVersion'], PluginFile.version(data)))
      raise ArgumentError, "Items files from #{problem}; export again with the current plugin"
    end
    unless data.is_a?(Hash) && data['items'].is_a?(Array) && !data.key?('recipes') && !data.key?('scenes')
      raise ArgumentError, 'Not an item catalog: expected an "items" list'
    end
    new(data)
  end

  # Why a file from game API +api_version+ and plugin +version+ has weights
  # and prices that can't be trusted (as "a plugin before ..., whose ..."),
  # or nil when they can.
  def self.problem(api_version, version)
    if !PluginFile.at_least?(version, MINIMUM_VERSION)
      "a plugin before #{MINIMUM_VERSION}, whose weights and prices are for whole stacks"
    elsif api_version.to_i >= PER_ITEM_API && !PluginFile.at_least?(version, FIXED_VERSION)
      "a plugin before #{FIXED_VERSION} on game API #{PER_ITEM_API} or later, whose weights and prices are " \
        'divided by the stack size twice'
    end
  end

  def initialize(data)
    @api_version = data['apiVersion']
    @plugin_version = data['pluginVersion'].presence
    # "new" (only items new or changed since the last export) or "all"
    # (plugin 0.8.0+); older files were always everything seen.
    @scope = data['scope'].presence
    @entries = data['items'].filter_map do |i|
      name = GameFinds.clean_name(i['name'])
      next if name.blank?
      Entry.new(i['key'].presence, name, GameWeights.decimal(i['weight']), i['value'], i['details'])
    end
  end

end
