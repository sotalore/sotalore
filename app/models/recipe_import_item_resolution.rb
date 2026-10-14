# frozen_string_literal: true

# Resolves items from a game export that the site doesn't recognize: names
# it doesn't know, and recipe slots taking any member of a group (whose key,
# see ItemGameKey, isn't recorded and whose name isn't a site group or
# category). Each can be:
#
#   created - a new Item with the game's name, of any kind (see
#             Item::ITEM_KINDS); a group's members are then curated on its
#             page. A group slot named like an existing item gets an "(any)"
#             suffix: "Dragon Head (any)"
#   renamed - an existing Item takes the game's name; its old name is kept
#             as an ItemAlias so anything still using it keeps resolving
#   aliased - the game's name becomes an ItemAlias of an existing Item
#   used    - an existing Item takes the game's keys, keeping its name
#
# Whichever it is, the item gets the game's keys, so later imports find it
# by key.
class RecipeImportItemResolution

  # Something in the export that doesn't resolve to a site item, and how the
  # export uses it: as an ingredient (or tool), as what a recipe makes, as
  # what a modification recipe takes and gives back, or as a group slot.
  # +complete+ is whether the export's group lists all its members (nil if
  # not a group slot, or the export has no groups list); +name_taken+ is
  # whether a site item already has the name.
  UnknownName = Data.define(:name, :entry_count, :as_ingredient, :as_tool, :as_result, :as_modified,
                            :group_slot, :keys, :complete, :name_taken) do
    def initialize(name:, entry_count:, as_ingredient: false, as_tool: false, as_result: false,
                   as_modified: false, group_slot: false, keys: [], complete: nil, name_taken: false)
      super
    end

    def to_s = name
    def group_slot? = group_slot

    # The kind it most likely is, going by how it's used.
    def likely_kind
      if group_slot? then complete == false ? 'category' : 'group'
      elsif as_modified && !as_result then 'category'
      elsif can_be_group? && name.match?(/ or /i) then 'group'
      else 'concrete'
      end
    end

    # The kinds it can be created as. The game's keys say whether it's a
    # group slot or an item; without keys, anything goes except that game
    # recipes don't make groups (a group can be what a modification acts on).
    def kinds
      if keys.any?
        group_slot? ? ItemGameKey::GROUP_KINDS : ItemGameKey::ITEM_KINDS
      else
        Item.kinds.keys - (can_be_group? ? [] : [ 'group' ])
      end
    end

    def can_be_group? = !as_result

    # The name a new item gets: the game's, unless a site item has it.
    def new_item_name
      group_slot? && name_taken ? "#{name} (any)" : name
    end
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
    complete = import.game_groups.to_h { [ _1.key, _1.complete? ] }
    names = {}
    info_for = lambda do |line, entry|
      names[[ line.name.downcase, line.group? ]] ||= {
        name: line.name, entries: Set.new, keys: Set.new, group_slot: line.group?,
        ingredient: false, tool: false, result: false, modified: false
      }
      info = names[[ line.name.downcase, line.group? ]]
      info[:entries] << entry.id
      info[:keys] << line.key if line.key
      info
    end

    import.entries.reject(&:final?).each do |entry|
      gr = entry.game_recipe
      modified = gr.modified_names.map(&:downcase)
      gr.ingredients.each do |line|
        next if lookup.known?(line)
        info = info_for.(line, entry)
        info[:ingredient] = true
        info[:tool] ||= line.tool?
      end
      gr.results.each do |line|
        next if lookup.known?(line)
        info = info_for.(line, entry)
        if modified.include?(line.name.downcase)
          info[:modified] = true
        else
          info[:result] = true
        end
      end
    end
    names.values
         .map do |i|
           keys = i[:keys].to_a.sort
           UnknownName.new(name: i[:name], entry_count: i[:entries].size, as_ingredient: i[:ingredient],
                           as_tool: i[:tool], as_result: i[:result], as_modified: i[:modified],
                           group_slot: i[:group_slot], keys: keys,
                           complete: (keys.map { complete[_1] }.compact.all? if i[:group_slot] && complete.any?),
                           name_taken: lookup.known?(i[:name]))
         end
         .sort_by { |u| [ -u.entry_count, u.name.downcase, u.group_slot? ? 1 : 0 ] }
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

  def create(name, kind: 'concrete', group_slot: false)
    unknown = find_unknown!(name, group_slot)
    kind = kind.to_s.presence_in(Item.kinds.keys) or raise Error, "Unknown kind #{kind.inspect}"
    raise Error, wrong_kind_message(unknown) unless unknown.kinds.include?(kind)
    if unknown.name_taken && !unknown.group_slot?
      raise Error, "The site already has an item named #{unknown.name}; rename that one first"
    end
    Item.transaction do
      item = Item.create!(
        name: unknown.new_item_name,
        kind: kind,
        source: unknown.as_result && kind == 'concrete' ? 'recipe' : 'unknown',
        use: unknown.as_tool ? 'tool' : 'unknown'
      )
      record_keys(item, unknown)
    end
  end

  def rename(item, name, group_slot: false)
    unknown = find_unknown!(name, group_slot)
    check_usable!(item)
    Item.transaction do
      old_name = item.name
      item.update!(name: unknown.name)
      RevisionRecorder.call(item, @user)
      ItemAlias.create!(name: old_name, item: item)
      record_keys(item, unknown)
    end
  end

  def alias(item, name, group_slot: false)
    unknown = find_unknown!(name, group_slot)
    check_usable!(item)
    Item.transaction do
      ItemAlias.create!(name: unknown.name, item: item)
      record_keys(item, unknown)
    end
  end

  # Gives +item+ the game's keys for the unknown, keeping its name: for when
  # the game names it differently (a group slot named like a concrete item,
  # say) but the site already has it.
  def use(item, name, group_slot: false)
    unknown = find_unknown!(name, group_slot)
    raise Error, "#{unknown.name} has no game keys to record; rename or alias instead" if unknown.keys.empty?
    record_keys(item, unknown)
  end

  # A key the game now names differently than the site (see GameKeyRecorder):
  # gives its item the game's name, keeping the old as an alias, or adds the
  # game's name as an alias.
  def adopt_game_name(key, as_alias: false)
    proposal = GameKeyRecorder.new(@import).proposals.find { _1.key == key && _1.status == 'renamed' } or
      raise Error, "#{key} isn't a renamed key in this import"
    item = proposal.item
    Item.transaction do
      if as_alias
        ItemAlias.create!(name: proposal.name, item: item)
      else
        old_name = item.name
        item.update!(name: proposal.name)
        RevisionRecorder.call(item, @user)
        ItemAlias.create!(name: old_name, item: item)
      end
      item.game_keys.find_by!(key: key).update!(name: proposal.name)
    end
    item
  end

  private

  def find_unknown!(name, group_slot)
    @import.unresolved_item_names.find { |u| u.name.casecmp?(name.to_s) && u.group_slot? == group_slot } or
      raise Error, "#{name.inspect} isn't an unknown #{group_slot ? 'group slot' : 'item'} in this import"
  end

  def wrong_kind_message(unknown)
    if unknown.group_slot?
      "#{unknown.name} is a slot taking any member of a group, so it can only be a group or category"
    elsif unknown.keys.any?
      "#{unknown.name} is an item in the game, so it can only be concrete or an archetype"
    else
      "A game recipe makes #{unknown.name}, and the game doesn't make groups; " \
        'if which one you get depends on the ingredients, make it an archetype'
    end
  end

  def record_keys(item, unknown)
    unknown.keys.each { |key| item.game_keys.create!(key: key, name: unknown.name) }
    item
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
