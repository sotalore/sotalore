# frozen_string_literal: true

# What applying a FindsImport would do, scene by scene: which site scene each
# matches (by the game's internal name, then by name), which of its items the
# site knows (by key, then by name), which creatures and nodes are new, and
# where the game's scene details disagree with the site's. Also what was
# targeted but never fought there (+seen+), which an admin adds as creatures
# or ignores (see IgnoredSighting), one by one.
class FindsImportAnalysis

  # An item found in a scene; +item+ is the site item, or nil if unknown.
  FoundItem = Data.define(:game_item, :item)
  # A node gathered from; +creature+ is whether it's field dressing.
  NodeRow = Data.define(:name, :creature, :existing, :items) do
    def creature? = creature
  end
  CreatureRow = Data.define(:name, :level_min, :level_max, :existing)
  # Targeted in the scene, never fought. +creature+ is the site's Creature of
  # that name, if any. +status+ is:
  #   pending - for an admin to add (or link) as a creature here, or ignore
  #   linked  - already one of the scene's creatures
  #   ignored - ignored in this scene
  #   dressed - field dressed here too, so a creature; applying links it
  SeenRow = Data.define(:name, :level_min, :level_max, :creature, :status) do
    def pending? = status == 'pending'
  end
  SceneRow = Data.define(:game, :scene, :items, :creatures, :seen, :nodes, :differences) do
    def unknown_items = items.reject(&:item)
    # What's for an admin to decide; not until the scene is matched.
    def pending_seen = scene ? seen.select(&:pending?) : []
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
      rows = finds.scenes.map { scene_row(_1) }
      load_sightings(rows)
      rows.map { _1.with(seen: seen_rows(_1)) }
    end
  end

  def pending_seen?
    scenes.any? { _1.pending_seen.any? }
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
    SceneRow.new(game, scene, items, creatures, [], nodes, scene ? differences(game, scene) : [])
  end

  # The site's creatures named in +seen+ lists, and for the matched scenes,
  # which are linked to them and which names are ignored there.
  def load_sightings(rows)
    names = rows.flat_map { _1.game.seen.map(&:name) }.uniq
    @seen_creatures = Creature.where(name: names).index_by { _1.name.downcase }
    scene_ids = rows.filter_map { _1.scene&.id }
    @linked = SceneCreature.where(scene_id: scene_ids, creature_id: @seen_creatures.values.map(&:id))
                           .pluck(:scene_id, :creature_id).to_set
    @ignored = IgnoredSighting.where(scene_id: scene_ids).pluck(:scene_id, :name)
                              .to_set { |id, name| [ id, name.downcase ] }
  end

  def seen_rows(row)
    row.game.seen.map do |sighting|
      key = sighting.name.downcase
      creature = @seen_creatures[key]
      status =
        if row.game.nodes.any? { _1.name.casecmp?(sighting.name) } then 'dressed'
        elsif row.scene && creature && @linked.include?([ row.scene.id, creature.id ]) then 'linked'
        elsif row.scene && @ignored.include?([ row.scene.id, key ]) then 'ignored'
        else 'pending'
        end
      SeenRow.new(sighting.name, sighting.level_min, sighting.level_max, creature, status)
    end
  end

  # A node's items come by name; the scene's items give their keys. A node
  # named like a creature, or like something targeted in the scene, is field
  # dressing.
  def node_row(game, node)
    creature = @creature_names.include?(node.name.downcase) || game.seen.any? { _1.name.casecmp?(node.name) }
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
