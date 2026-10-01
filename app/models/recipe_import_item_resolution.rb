# frozen_string_literal: true

# Resolves item names from a game export that the site doesn't recognize.
# Each unknown name can be:
#
#   created - a new Item with the game's name, optionally as a group
#             (abstract item) whose members are then curated on its page
#   renamed - an existing Item takes the game's name; its old name is kept
#             as an ItemAlias so anything still using it keeps resolving
#   aliased - the game's name becomes an ItemAlias of an existing Item
class RecipeImportItemResolution

  # An item name from the export that doesn't resolve to a site item.
  UnknownName = Data.define(:name, :entry_count, :as_tool, :as_result) do
    def to_s = name
  end

  # A site item that might be what the game means by an unknown name.
  Suggestion = Data.define(:item, :similarity, :game_uses_name) do
    # If the game also uses this item's current name, it's a distinct item
    # and must not be renamed or aliased.
    def usable? = !game_uses_name
  end

  SUGGESTION_THRESHOLD = 0.3

  class Error < StandardError; end

  # All UnknownNames across the import's pending entries, most used first.
  def self.unresolved_names(import, lookup: ItemLookup.new)
    names = {}
    import.entries.reject(&:final?).each do |entry|
      gr = entry.game_recipe
      gr.ingredients.each do |line|
        next if lookup.known?(line.name)
        info = (names[line.name.downcase] ||= { name: line.name, entries: Set.new, tool: false, result: false })
        info[:entries] << entry.id
        info[:tool] ||= line.tool?
      end
      gr.results.each do |line|
        next if lookup.known?(line.name)
        info = (names[line.name.downcase] ||= { name: line.name, entries: Set.new, tool: false, result: false })
        info[:entries] << entry.id
        info[:result] = true
      end
    end
    names.values
         .map { |i| UnknownName.new(i[:name], i[:entries].size, i[:tool], i[:result]) }
         .sort_by { |u| [ -u.entry_count, u.name.downcase ] }
  end

  def initialize(import, user)
    @import = import
    @user = user
  end

  # Site items with names similar to +name+ (pg_trgm), best first.
  def suggestions_for(name, limit: 4)
    suggestions_for_names([ name ], limit: limit).fetch(name)
  end

  # Suggestions for many names at once, as { name => [Suggestion] }, in two
  # queries however many names there are. The game often qualifies names the
  # site doesn't, e.g. "Citrine (Unrefined Gemstone)" for "Citrine", so an
  # exact match on the unqualified name comes first.
  def suggestions_for_names(names, limit: 4)
    names = names.uniq
    return {} if names.empty?

    unqualified = names.to_h { |name| [ name, name.sub(/\s*\([^)]*\)\z/, '') ] }
                       .reject { |name, base| name == base }
    exact = if unqualified.any?
      Item.where('lower(items.name) IN (?)', unqualified.values.map(&:downcase))
          .index_by { |item| item.name.downcase }
    else
      {}
    end

    similar = Item.find_by_sql([ <<~SQL, names, SUGGESTION_THRESHOLD, limit ]).group_by(&:query_name)
      SELECT matches.*, q.name AS query_name
      FROM unnest(ARRAY[?]::text[]) AS q(name)
      CROSS JOIN LATERAL (
        SELECT items.*, similarity(items.name, q.name) AS name_similarity
        FROM items
        WHERE similarity(items.name, q.name) > ?
        ORDER BY name_similarity DESC, items.id
        LIMIT ?
      ) AS matches
    SQL

    names.index_with do |name|
      exact_item = exact[unqualified[name]&.downcase]
      pairs = Array(similar[name]).reject { |item| item.id == exact_item&.id }
                                  .map { |item| [ item, item.name_similarity.to_f.round(2) ] }
      pairs.unshift([ exact_item, 1.0 ]) if exact_item
      pairs.first(limit).map do |item, score|
        Suggestion.new(item, score, game_names.include?(item.name.downcase))
      end
    end
  end

  def create(name, group: false)
    unknown = find_unknown!(name)
    if group && unknown.as_result
      raise Error, "#{unknown.name} is made by a game recipe, so it's a concrete item, not a group"
    end
    Item.create!(
      name: unknown.name,
      abstract: group,
      source: unknown.as_result ? 'recipe' : 'unknown',
      use: unknown.as_tool ? 'tool' : 'unknown'
    )
  end

  def rename(item, name)
    unknown = find_unknown!(name)
    check_usable!(item)
    Item.transaction do
      old_name = item.name
      item.update!(name: unknown.name)
      RevisionRecorder.call(item, @user)
      ItemAlias.create!(name: old_name, item: item)
    end
    item
  end

  def alias(item, name)
    unknown = find_unknown!(name)
    check_usable!(item)
    ItemAlias.create!(name: unknown.name, item: item)
    item
  end

  private

  def find_unknown!(name)
    lookup = ItemLookup.new
    raise Error, "#{name.inspect} is already a known item" if lookup.known?(name)
    @import.unresolved_item_names.find { |u| u.name.casecmp?(name.to_s) } or
      raise Error, "#{name.inspect} isn't an unknown item in this import"
  end

  def check_usable!(item)
    if game_names.include?(item.name.downcase)
      raise Error, "The game also uses #{item.name.inspect}, so it's a different item"
    end
  end

  def game_names
    @game_names ||= @import.entries.flat_map { |e| e.game_recipe.item_names }.map(&:downcase).to_set
  end

end
