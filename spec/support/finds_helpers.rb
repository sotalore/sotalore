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
