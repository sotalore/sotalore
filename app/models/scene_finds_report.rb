# frozen_string_literal: true

# Which scenes have had their finds imported (Scene#finds_imported_at, set
# by FindsImport), for working out where to play next to gather more. Lower
# tiers come first by default, as they're the easiest to gather in.
#
#   SceneFindsReport.new(region: 1, status: 'missing', sort: 'tier').scenes
class SceneFindsReport

  STATUSES = { 'missing' => 'Not imported', 'imported' => 'Imported', 'all' => 'All' }.freeze
  SORTS = { 'tier' => 'Tier', 'name' => 'Name', 'imported' => 'Oldest import' }.freeze

  attr_reader :region, :scene_type, :status, :sort

  def initialize(region: nil, scene_type: nil, status: nil, sort: nil)
    @region = Integer(region, exception: false)
    @scene_type = Integer(scene_type, exception: false)
    @status = STATUSES.key?(status) ? status : 'missing'
    @sort = SORTS.key?(sort) ? sort : 'tier'
  end

  # The scenes, each with items_count, creatures_count and nodes_count. The
  # top-level Overworld (the whole map) isn't a place to play, so it's left out.
  def scenes
    scope = Scene.where.not(parent_id: nil).select('scenes.*', *counts)
    scope = scope.where(region_id: region) if region
    scope = scope.where(scene_type_id: scene_type) if scene_type
    scope = scope.where(finds_imported_at: nil) if status == 'missing'
    scope = scope.where.not(finds_imported_at: nil) if status == 'imported'
    scope.order(Arel.sql(ORDER.fetch(sort)))
  end

  # How many scenes (of the region and type chosen) have had finds imported.
  def progress
    scope = Scene.where.not(parent_id: nil)
    scope = scope.where(region_id: region) if region
    scope = scope.where(scene_type_id: scene_type) if scene_type
    [ scope.where.not(finds_imported_at: nil).count, scope.count ]
  end

  private

  ORDER = {
    'tier' => 'scenes.level_id ASC NULLS LAST, lower(scenes.name)',
    'name' => 'lower(scenes.name)',
    'imported' => 'scenes.finds_imported_at ASC NULLS FIRST, lower(scenes.name)',
  }.freeze

  def counts
    { 'items' => 'scene_finds', 'creatures' => 'scene_creatures', 'nodes' => 'scene_nodes' }.map do |name, table|
      "(SELECT count(*) FROM #{table} WHERE #{table}.scene_id = scenes.id) AS #{name}_count"
    end
  end

end
