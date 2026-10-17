# frozen_string_literal: true

# A read-only view over the plugin's finds file (see sl-lua/EXPORT-FORMAT.md):
# per scene, the items gained there, the creatures fought there, and the
# nodes gathered from (with what each gave), e.g.
#
#   {"apiVersion":40,"scenes":[{"scene":"Kingsroad","rawName":"HiddenVale_Plains02_Road_Tier1",
#     "info":{"isPvp":false,...},
#     "items":[{"key":"item:...","name":"Animal Hide","quantity":12,"times":2}],
#     "creatures":[{"name":"Brown Bear","seen":3,"levelMin":18,"levelMax":18}],
#     "nodes":[{"name":"Copper Vein","items":[{"name":"Copper Ore","quantity":9}]}]}]}
#
# The site only cares that something can be found somewhere, so counts are
# ignored. A node named like a creature is field dressing: its items are the
# creature's.
class GameFinds

  Item = Data.define(:key, :name)
  CreatureSighting = Data.define(:name, :level_min, :level_max)
  Node = Data.define(:name, :item_names)
  Scene = Data.define(:name, :raw_name, :info, :items, :creatures, :nodes) do
    # The scene's items by name, for nodes, which give names only.
    def item_named(name)
      items.find { _1.name.casecmp?(name) }
    end
  end

  attr_reader :api_version, :plugin_version, :scenes

  # Raises ArgumentError for anything that isn't a finds file.
  def self.parse(json)
    data = json.is_a?(String) ? JSON.parse(json) : json
    PluginFile.check_type!(data, 'finds')
    unless data.is_a?(Hash) && data['scenes'].is_a?(Array)
      raise ArgumentError, 'Not a finds file: expected a "scenes" list'
    end
    new(data)
  end

  # The game passes formatting markers through in names ("[u]...[/u]").
  def self.clean_name(name)
    name.to_s.gsub(%r{\[/?[a-z]+\]}i, '').squish
  end

  def initialize(data)
    @api_version = data['apiVersion']
    @plugin_version = data['pluginVersion'].presence
    @scenes = data['scenes'].map { scene(_1) }.reject { _1.name.blank? }
  end

  def creature_names
    scenes.flat_map(&:creatures).map(&:name).uniq
  end

  private

  def scene(s)
    Scene.new(
      name: self.class.clean_name(s['scene']),
      raw_name: s['rawName'].presence,
      info: s['info'],
      items: Array(s['items']).map { Item.new(_1['key'].presence, self.class.clean_name(_1['name'])) }
                              .reject { _1.name.blank? },
      creatures: Array(s['creatures']).map do
        CreatureSighting.new(self.class.clean_name(_1['name']), _1['levelMin'], _1['levelMax'])
      end.reject { _1.name.blank? },
      nodes: Array(s['nodes']).map do
        Node.new(self.class.clean_name(_1['name']),
                 Array(_1['items']).map { |i| self.class.clean_name(i['name']) }.compact_blank.uniq)
      end.reject { _1.name.blank? }
    )
  end

end
