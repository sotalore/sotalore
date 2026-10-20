# frozen_string_literal: true

# One uploaded finds file from the game plugin (see GameFinds). It's
# reviewed (see FindsImportAnalysis) and then applied (see #apply!), which
# records what can be found where: which items in which scene, which
# creatures and gathering nodes are there, and what they yield. Applying is
# idempotent, so an import can be applied again after resolving more of it.
class FindsImport < ApplicationRecord
  include GameItemResolution

  belongs_to :uploaded_by, class_name: 'User', optional: true

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  # Raises ArgumentError or JSON::ParserError for anything that isn't a
  # finds file.
  def self.create_from_json!(json, filename: nil, user: nil)
    data = JSON.parse(json)
    finds = GameFinds.parse(data)
    raise ArgumentError, 'No scenes found' if finds.scenes.empty?
    create!(filename: filename, api_version: finds.api_version, plugin_version: finds.plugin_version,
            payload: data, uploaded_by: user)
  end

  def finds
    @finds ||= GameFinds.parse(payload)
  end

  def analysis
    @analysis ||= FindsImportAnalysis.new(self)
  end

  def reload(*)
    @analysis = nil
    @finds = nil
    super
  end

  # Records what the matched scenes say can be found there, as +user+.
  # Unmatched scenes and unknown items are left out until resolved. Returns
  # { what => how many new rows }.
  def apply!
    counts = Hash.new(0)
    lookup = ItemLookup.new
    transaction do
      analysis.scenes.each do |row|
        next unless row.scene
        apply_scene(row, lookup, counts)
      end
      update!(applied_at: Time.current)
    end
    @analysis = nil
    counts
  end

  def to_s
    "Finds ##{id}"
  end

  # Takes +scene+ as the export's scene named +name+, by recording the
  # game's internal name for it.
  def link_scene!(name, scene)
    row = analysis.unmatched_scenes.find { _1.game.name.casecmp?(name) } or
      raise Error, "#{name} isn't an unmatched scene in this import"
    raise Error, "The export gives #{name} no internal name to link by" unless row.game.raw_name
    raise Error, "#{scene.name} is already linked to #{scene.game_name}" if scene.game_name
    scene.update!(game_name: row.game.raw_name)
    @analysis = nil
    scene
  end

  # Takes +name+, targeted but never fought in the site scene +scene_id+
  # (see FindsImportAnalysis::SeenRow), as a creature living there: creates
  # the Creature unless the site has it, and links it to the scene with the
  # levels seen. Returns the creature.
  def add_seen_creature!(scene_id, name)
    row, seen = pending_seen(scene_id, name)
    creature = seen.creature || Creature.create!(name: seen.name)
    link = SceneCreature.find_or_initialize_by(scene: row.scene, creature: creature)
    link.widen(seen.level_min, seen.level_max)
    link.save!
    @analysis = nil
    creature
  end

  # Ignores +name+ in the site scene +scene_id+ (see IgnoredSighting), so
  # this and later imports leave it out of review there.
  def ignore_seen!(scene_id, name)
    row, seen = pending_seen(scene_id, name)
    IgnoredSighting.create!(scene: row.scene, name: seen.name)
    @analysis = nil
  end

  private

  def pending_seen(scene_id, name)
    row = analysis.scenes.find { _1.scene&.id == scene_id.to_i } or
      raise Error, "This import has no scene ##{scene_id} on the site"
    seen = row.pending_seen.find { _1.name.casecmp?(name) } or
      raise Error, "#{name} isn't waiting for review in #{row.scene.name}"
    [ row, seen ]
  end

  def reset_analysis!
    @analysis = nil
  end

  def apply_scene(row, lookup, counts)
    scene = row.scene
    if scene.game_name.nil? && row.game.raw_name && !Scene.exists?(game_name: row.game.raw_name)
      scene.update_columns(game_name: row.game.raw_name)
    end
    scene.update_columns(finds_imported_at: Time.current)

    row.items.each do |found|
      next unless found.item
      record_key(found.game_item.key, found.item, found.game_item.name, lookup)
      counts[:items] += 1 if create_once(SceneFind, scene: scene, item: found.item)
    end

    row.creatures.each do |sighting|
      creature = Creature.find_or_create_by!(name: sighting.name)
      link = SceneCreature.find_or_initialize_by(scene: scene, creature: creature)
      counts[:creatures] += 1 if link.new_record?
      link.widen(sighting.level_min, sighting.level_max)
      link.save!
    end

    row.nodes.each do |node|
      source =
        if node.creature?
          creature = Creature.find_or_create_by!(name: node.name)
          counts[:creatures] += 1 if create_once(SceneCreature, scene: scene, creature: creature)
          creature
        else
          gathering_node = GatheringNode.find_or_create_by!(name: node.name)
          counts[:nodes] += 1 if create_once(SceneNode, scene: scene, gathering_node: gathering_node)
          gathering_node
        end
      node.items.each do |found|
        next unless found.item
        counts[:yields] += 1 if create_once(HarvestYield, source: source, item: found.item)
      end
    end
  end

  # Creates the row unless it exists; true when it was created. Touches an
  # existing one, so updated_at says when it was last seen.
  def create_once(model, **attributes)
    existing = model.find_by(attributes)
    existing ? (existing.touch && false) : (model.create!(attributes) && true)
  end

  # Records the game's key for an item found by name, as recipe imports do.
  def record_key(key, item, name, lookup)
    return if key.nil? || lookup.id_for_key(key)
    return unless ItemGameKey.suits?(key, item)
    ItemGameKey.create!(key: key, item: item, name: name)
    lookup.remember_key(key, item.id)
  end
end
