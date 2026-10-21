# frozen_string_literal: true

# Builds finds files shaped like the game plugin's (see sl-lua/EXPORT-FORMAT.md).
module FindsHelpers
  # +items+ is { name => key }; +creatures+ { name => [min, max] }; +nodes+
  # { name => [item names] }.
  def finds_scene_hash(scene:, raw_name: "#{scene.delete(' ')}_Raw", items: {}, creatures: {}, seen: nil, nodes: {}, info: nil)
    {
      'scene' => scene, 'rawName' => raw_name, 'info' => info,
      'items' => items.map { |name, key| { 'key' => key, 'name' => name, 'quantity' => 1, 'times' => 1 } },
      'creatures' => creatures.map { |name, (min, max)| { 'name' => name, 'seen' => 1, 'levelMin' => min, 'levelMax' => max } },
      'nodes' => nodes.map { |name, names| { 'name' => name, 'harvests' => 1, 'items' => names.map { { 'name' => _1, 'quantity' => 1 } } } },
    }.merge(seen ? { 'seen' => seen.map { |name, (min, max)| { 'name' => name, 'seen' => 1, 'levelMin' => min, 'levelMax' => max } } } : {})
  end

  def finds_json(*scenes)
    { 'apiVersion' => 40, 'scenes' => scenes }.to_json
  end
end

RSpec.configure do |config|
  config.include FindsHelpers
end

# Builds item catalogs shaped like the game plugin's.
module CatalogHelpers
  # +salvage+ is { name => [min, max, chance] }.
  def catalog_entry(name:, key: item_key(name), weight: 1, value: 1, tool: false, crafted: false,
                    salvage: nil, yields: nil, hovered: true)
    details =
      if hovered
        base = { 'crafted' => crafted, 'salvage' => (salvage || {}).map { |n, (min, max, chance)| { 'name' => n, 'min' => min, 'max' => max, 'chance' => chance } },
                 'yields' => yields }
        crafted ? base : base.merge('tool' => tool, 'questItem' => false, 'merchantPays' => nil, 'text' => name)
      end
    { 'key' => key, 'name' => name, 'weight' => weight, 'value' => value, 'createdBy' => '', 'details' => details }
  end

  def catalog_json(*entries, plugin_version: '0.8.1', api_version: 40)
    { 'apiVersion' => api_version, 'pluginVersion' => plugin_version, 'type' => 'items', 'scope' => 'all',
      'count' => entries.size, 'items' => entries }.compact.to_json
  end
end

RSpec.configure do |config|
  config.include CatalogHelpers
end
