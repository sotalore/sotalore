# frozen_string_literal: true

# Builds finds files shaped like the game plugin's (see sl-lua/EXPORT-FORMAT.md).
module FindsHelpers
  # +items+ is { name => key }; +creatures+ { name => [min, max] }; +nodes+
  # { name => [item names] }.
  def finds_scene_hash(scene:, raw_name: "#{scene.delete(' ')}_Raw", items: {}, creatures: {}, nodes: {}, info: nil)
    {
      'scene' => scene, 'rawName' => raw_name, 'info' => info,
      'items' => items.map { |name, key| { 'key' => key, 'name' => name, 'quantity' => 1, 'times' => 1 } },
      'creatures' => creatures.map { |name, (min, max)| { 'name' => name, 'seen' => 1, 'levelMin' => min, 'levelMax' => max } },
      'nodes' => nodes.map { |name, names| { 'name' => name, 'harvests' => 1, 'items' => names.map { { 'name' => _1, 'quantity' => 1 } } } },
    }
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

  def catalog_json(*entries)
    { 'apiVersion' => 40, 'count' => entries.size, 'items' => entries }.to_json
  end
end

RSpec.configure do |config|
  config.include CatalogHelpers
end
