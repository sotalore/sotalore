# frozen_string_literal: true

# One uploaded item catalog from the game plugin (see GameCatalog): items
# seen in a character's bags, and their tooltips. Reviewed (see
# ItemCatalogAnalysis) and applied (see #apply!), which records the game's
# keys and tooltips, fills weights the site lacks, makes tools of unknown-use
# items the tooltip calls tools, and brings in salvage lists with their
# quantities and chances. A crafted item gives only its salvage list.
# Applying is idempotent. Only files whose weights are per item, or null when
# not known, are taken (see GameCatalog.problem).
class ItemCatalogImport < ApplicationRecord
  include GameItemResolution

  belongs_to :uploaded_by, class_name: 'User', optional: true

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  # Raises ArgumentError or JSON::ParserError for anything that isn't an
  # item catalog.
  def self.create_from_json!(json, filename: nil, user: nil)
    data = JSON.parse(json)
    catalog = GameCatalog.parse(data)
    raise ArgumentError, 'No items found' if catalog.entries.empty?
    create!(filename: filename, api_version: catalog.api_version, plugin_version: catalog.plugin_version,
            payload: data, uploaded_by: user)
  end

  # Parsed without the version check, so an import stored before it (or from
  # an older plugin) can still be looked at and deleted.
  def catalog
    @catalog ||= GameCatalog.parse(payload, require_version: false)
  end

  # Why it can't be applied (see GameCatalog.problem), or nil.
  def problem
    GameCatalog.problem(catalog.api_version, catalog.plugin_version)
  end

  def supported? = problem.nil?

  def analysis
    @analysis ||= ItemCatalogAnalysis.new(self)
  end

  def reload(*)
    @catalog = nil
    reset_analysis!
    super
  end

  def to_s
    "Item Catalog ##{id}"
  end

  # Applies what the catalog says about the items the site knows, as +user+,
  # recording revisions. Returns { what => how many }.
  def apply!(user)
    unsupported!
    counts = Hash.new(0)
    lookup = ItemLookup.new
    now = Time.current
    transaction do
      analysis.rows.select(&:known?).each do |row|
        entry, item = row.entry, row.item
        unless entry.crafted?
          counts[:keys] += 1 if record_key(entry, item, lookup)
          record_catalog(entry, now)
        end

        item.weight = entry.weight if row.missing_weight?
        item.use = 'tool' if row.tool?
        if item.changed?
          counts[:weights] += 1 if item.weight_changed?
          counts[:tools] += 1 if item.use_changed?
          item.save!
          RevisionRecorder.call(item, user)
        end

        row.salvage.select(&:known?).each do |salvage|
          counts[salvage.site ? :salvage_updated : :salvage_added] += 1 if salvage.missing? || salvage.changed?
          record_salvage(item, salvage, now)
        end
      end
      update!(applied_at: now)
    end
    reset_analysis!
    counts
  end

  # Replaces the site's weights that differ from the game's with the game's,
  # recording revisions. Returns how many.
  def update_weights!(user)
    unsupported!
    rows = analysis.rows.select(&:different_weight?)
    transaction do
      rows.each do |row|
        row.item.update!(weight: row.entry.weight)
        RevisionRecorder.call(row.item, user)
      end
    end
    reset_analysis!
    rows.size
  end

  # Removes the site's salvages from +item+ that the game's list doesn't
  # have. Returns how many.
  def remove_extra_salvage!(item)
    row = analysis.rows.find { _1.item == item } or raise Error, "#{item.name} isn't in this catalog"
    row.extra_salvage.each(&:destroy!)
    reset_analysis!
    row.extra_salvage.size
  end

  private

  def reset_analysis!
    @analysis = nil
  end

  def unsupported!
    return if supported?
    raise Error, "#{self} is from #{problem}; delete it and import a new export"
  end

  def record_key(entry, item, lookup)
    return false if entry.key.nil? || lookup.id_for_key(entry.key) || !ItemGameKey.suits?(entry.key, item)
    ItemGameKey.create!(key: entry.key, item: item, name: entry.name)
    lookup.remember_key(entry.key, item.id)
    true
  end

  # Keeps what the tooltip said on the item's game key, for later use. A null
  # value isn't known (the item wasn't in the bags), so keeps the one before.
  def record_catalog(entry, now)
    game_key = entry.key && ItemGameKey.find_by(key: entry.key) or return
    catalog = { 'value' => entry.value }.compact
    catalog['details'] = entry.details if entry.details?
    game_key.update!(catalog: (game_key.catalog || {}).merge(catalog), catalog_seen_at: now)
  end

  def record_salvage(item, salvage, now)
    record = salvage.site || ItemSalvage.new(salvage_from: item, salvage_to: salvage.item)
    record.update!(min_count: salvage.game.min, max_count: salvage.game.max, chance: salvage.game.chance,
                   game_synced_at: now)
  end
end
