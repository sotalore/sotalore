# frozen_string_literal: true

# What applying a FindsImport would do, scene by scene: which site scene each
# matches (by the game's internal name, then by name), which of its items the
# site knows (by key, then by name), which creatures and nodes are new, and
# where the game's scene details disagree with the site's.
class FindsImportAnalysis

  # An item found in a scene; +item+ is the site item, or nil if unknown.
  FoundItem = Data.define(:game_item, :item)
  # A node gathered from; +creature+ is whether it's field dressing.
  NodeRow = Data.define(:name, :creature, :existing, :items) do
    def creature? = creature
  end
  CreatureRow = Data.define(:name, :level_min, :level_max, :existing)
  SceneRow = Data.define(:game, :scene, :items, :creatures, :nodes, :differences) do
    def unknown_items = items.reject(&:item)
  end
  # An item the site doesn't know, and the scenes it was found in.
  UnknownItem = Data.define(:key, :name, :scene_names)

  def initialize(import, lookup: ItemLookup.new)
    @import = import
    @lookup = lookup
  end

  def scenes
    @scenes ||= begin
      finds = @import.finds
      @creature_names = (Creature.pluck(:name) + finds.creature_names).map(&:downcase).to_set
      @existing_creatures = Creature.pluck(:name).map(&:downcase).to_set
      @existing_nodes = GatheringNode.pluck(:name).map(&:downcase).to_set
      @items = Item.where(id: finds.scenes.flat_map(&:items).filter_map { @lookup.id_for(_1) }).index_by(&:id)
      finds.scenes.map { scene_row(_1) }
    end
  end

  def unmatched_scenes
    scenes.reject(&:scene)
  end

  # Unknown items across all scenes, by key (or name when there's no key).
  def unknown_items
    scenes.flat_map { |row| row.unknown_items.map { [ row.game.name, _1.game_item ] } }
          .group_by { |_, item| item.key || item.name.downcase }
          .map { |_, rows| UnknownItem.new(rows.first.last.key, rows.first.last.name, rows.map(&:first).uniq) }
          .sort_by { _1.name.downcase }
  end

  def new_creatures
    scenes.flat_map { |row| row.creatures.reject(&:existing).map(&:name) +
                             row.nodes.select { _1.creature? && !_1.existing }.map(&:name) }
          .uniq(&:downcase).sort
  end

  def new_nodes
    scenes.flat_map { |row| row.nodes.reject { _1.creature? || _1.existing }.map(&:name) }.uniq(&:downcase).sort
  end

  private

  def scene_row(game)
    scene = (game.raw_name && Scene.find_by(game_name: game.raw_name)) ||
            Scene.where('lower(name) = ?', game.name.downcase).first
    items = game.items.map { FoundItem.new(_1, @items[@lookup.id_for(_1)]) }
    creatures = game.creatures.map do
      CreatureRow.new(_1.name, _1.level_min, _1.level_max, @existing_creatures.include?(_1.name.downcase))
    end
    nodes = game.nodes.map { node_row(game, _1) }
    SceneRow.new(game, scene, items, creatures, nodes, scene ? differences(game, scene) : [])
  end

  # A node's items come by name; the scene's items give their keys.
  def node_row(game, node)
    creature = @creature_names.include?(node.name.downcase)
    existing = creature ? @existing_creatures.include?(node.name.downcase) : @existing_nodes.include?(node.name.downcase)
    items = node.item_names.map do |name|
      game_item = game.item_named(name) || GameFinds::Item.new(nil, name)
      id = @lookup.id_for(game_item)
      FoundItem.new(game_item, id && (@items[id] ||= Item.find_by(id: id)))
    end
    NodeRow.new(node.name, creature, existing, items)
  end

  # [ [what, site, game] ] where the game's scene details disagree.
  def differences(game, scene)
    info = game.info or return []
    rows = []
    rows << [ 'PvP', scene.pvp?, info['isPvp'] ] if !info['isPvp'].nil? && scene.pvp? != info['isPvp']
    { 'Dungeon' => 'isDungeon', 'Player Owned Town (POT)' => 'isPot', 'Overworld' => 'isOverworld' }.each do |type, flag|
      next if info[flag].nil?
      site = scene.scene_type == type
      rows << [ type, site, info[flag] ] if site != info[flag]
    end
    rows
  end

end
