# frozen_string_literal: true

# What applying an ItemCatalogImport would do, item by item: which site item
# each is (by key, then by name), whether its weight is missing or differs,
# whether its value (from the tooltip) is new or changed, whether its use
# should be tool, and how the tooltip's salvage list compares
# with the site's salvages.
#
# A crafted item ("Cotton Cloth Leggings +2") is one of a kind sharing its
# base item's key, so it's matched by key only, and only its salvage list is
# used. Even that depends on its materials ("Supple Epic Leather Gloves"
# give Yard of Supple Leather, plain Epic Leather Boots Yard of Simple
# Leather), so it's only used when the crafted name, less "+N" and an
# "of ..." enchantment, is the base item's name. Unknown crafted items are
# skipped, not offered for creating. Salvage is only taken for concrete
# items: an archetype's ("Dagger") depends on what it was made from.
class ItemCatalogAnalysis

  # A salvage the game lists: +item+ is the component's site item (nil if
  # unknown), +site+ the site's ItemSalvage for it, if any.
  SalvageRow = Data.define(:game, :item, :site) do
    def known? = !item.nil?
    def missing? = known? && site.nil?

    def changed?
      site && [ site.min_count, site.max_count, site.chance&.to_f ] != [ game.min, game.max, game.chance&.to_f ]
    end
  end

  Row = Data.define(:entry, :item, :salvage, :extra_salvage) do
    def known? = !item.nil?
    def missing_weight? = known? && !entry.crafted? && item.weight.nil? && !entry.weight.nil?

    def different_weight?
      known? && !entry.crafted? && item.weight && entry.weight && item.weight != entry.weight
    end

    def tool? = known? && !entry.crafted? && entry.tool? && item.use_is_unknown?

    # Only a concrete item has a value; an archetype's depends on its material.
    def value_change?
      known? && item.concrete? && !entry.crafted? && !entry.tooltip_value.nil? && item.value != entry.tooltip_value
    end

    def salvage_changes? = salvage.any? { _1.missing? || _1.changed? }
    def interesting? = missing_weight? || different_weight? || value_change? || tool? || salvage_changes? || extra_salvage.any?
  end

  UnknownItem = Data.define(:key, :name, :uses)

  def initialize(import, lookup: ItemLookup.new)
    @import = import
    @lookup = lookup
  end

  # Crafted entries the site doesn't have the base item of, left out.
  def skipped_crafted
    rows && @skipped_crafted
  end

  def rows
    @rows ||= begin
      entries = @import.catalog.entries
      names = entries.flat_map { |e| e.salvage.map(&:name) }
      ids = entries.filter_map { @lookup.id_for(_1) } + names.filter_map { @lookup.id_for(_1) }
      @items = Item.where(id: ids).includes(:item_salvages_as_source).index_by(&:id)
      all = entries.map { row(_1) }
      @skipped_crafted = all.select { _1.entry.crafted? && !_1.known? }.map(&:entry)
      (all - all.select { _1.entry.crafted? && !_1.known? })
        .sort_by { [ _1.known? ? 0 : 1, _1.entry.name.downcase ] }
    end
  end

  # Salvage components the site doesn't know (needed for the salvage lists),
  # then catalog items it doesn't know.
  def unknown_items
    unknown_components + (unknown_catalog_items.reject { |u| unknown_components.any? { _1.name.casecmp?(u.name) } })
  end

  def unknown_components
    @unknown_components ||=
      rows.flat_map { |row| row.salvage.reject(&:known?).map { [ _1.game.name, row.entry.name ] } }
          .group_by { _1.first.downcase }
          .map { |_, pairs| UnknownItem.new(nil, pairs.first.first, "salvaged from #{pairs.map(&:last).uniq.to_sentence}") }
          .sort_by { _1.name.downcase }
  end

  def unknown_catalog_items
    rows.reject(&:known?).map { UnknownItem.new(_1.entry.key, _1.entry.name, 'in the catalog') }
        .sort_by { _1.name.downcase }
  end

  def counts
    {
      known: rows.count(&:known?), unknown: rows.count { !_1.known? }, skipped_crafted: skipped_crafted.size,
      missing_weights: rows.count(&:missing_weight?), different_weights: rows.count(&:different_weight?),
      values: rows.count(&:value_change?), tools: rows.count(&:tool?), salvage_items: rows.count(&:salvage_changes?),
      salvage_to_add: rows.sum { |r| r.salvage.count(&:missing?) },
      salvage_to_update: rows.sum { |r| r.salvage.count(&:changed?) },
      extra_salvage: rows.sum { _1.extra_salvage.size },
    }
  end

  private

  # Whether a crafted item is just its base item made by a player, so its
  # salvage is the base item's.
  def plain_kind?(entry, item)
    return true unless entry.crafted?
    unplussed = entry.name.sub(/\s\+\d+\z/, '')
    [ entry.name, unplussed, unplussed.sub(/\s+of\s.+\z/, '') ].any? { _1.casecmp?(item.name) }
  end

  def row(entry)
    id = entry.crafted? ? @lookup.id_for_key(entry.key) : @lookup.id_for(entry)
    item = @items[id] || (id && Item.find_by(id: id))
    return Row.new(entry, item, [], []) unless item&.concrete? && entry.details? && plain_kind?(entry, item)

    site = item.item_salvages_as_source.index_by(&:salvage_to_id)
    salvage = entry.salvage.map do |game|
      component = @items[@lookup.id_for(game.name)]
      SalvageRow.new(game, component, component && site[component.id])
    end
    listed = salvage.filter_map { _1.item&.id }
    extra = site.values.reject { listed.include?(_1.salvage_to_id) }
    Row.new(entry, item, salvage, extra)
  end

end
