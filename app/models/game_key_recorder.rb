# frozen_string_literal: true

# Records the game's keys (see ItemGameKey) for site items, from a recipe
# import: each key the export's recipes use is matched to a site item by the
# name the game gives it. Previews what it would do (#proposals), then
# records the safe ones (#record!). Keys whose names don't lead to exactly one
# suitable item are left for an admin:
#
#   record    - new key; its name is a site item of a suitable kind
#   known     - already recorded for the item its name leads to
#   renamed   - already recorded, but the game now uses a name the site
#               doesn't know: renamed in the game
#   elsewhere - already recorded for a different item than its name leads to
#               (the game may have renamed it)
#   ambiguous - the export uses its name for more than one key, so which is
#               which can't be told by name
#   unsuited  - its name is a site item of the wrong kind: a group slot named
#               like a concrete item ("Dragon Head"), or an item named like
#               a site group
#   unknown   - its name isn't a site item yet (see the import's unknown items)
#
# An ambiguous key can still be recorded for the item its name leads to by
# hand (#record_one!), when the site doesn't tell the variants apart.
#
# Two group keys with the same name and the same members (the game has two
# "Gem Fragment" groups) aren't ambiguous: both stand for the same thing.
class GameKeyRecorder

  STATUSES = %w[ record known renamed elsewhere ambiguous unsuited unknown ].freeze

  Proposal = Data.define(:key, :name, :stats, :item, :status, :note) do
    def group_key? = ItemGameKey.group_key?(key)
  end

  def initialize(import, lookup: ItemLookup.new)
    @import = import
    @lookup = lookup
  end

  def proposals
    @proposals ||= begin
      keys = seen_keys
      ambiguous = ambiguous_keys(keys)
      recorded = ItemGameKey.where(key: keys.keys).index_by(&:key)
      items = Item.where(id: keys.values.filter_map { @lookup.id_for(_1[:name]) } + recorded.values.map(&:item_id))
                  .index_by(&:id)
      keys.map do |key, seen|
        proposal(key, seen, recorded[key], items, ambiguous)
      end.sort_by { |p| [ STATUSES.index(p.status), p.name.downcase, p.key ] }
    end
  end

  def counts
    STATUSES.index_with { |status| proposals.count { _1.status == status } }
  end

  # Records the new keys, and refreshes the name and stats of known ones.
  # Returns how many were added.
  def record!
    now = Time.current
    added = proposals.select { _1.status == 'record' }
    ItemGameKey.transaction do
      if added.any?
        ItemGameKey.insert_all!(added.map do |p|
          { key: p.key, item_id: p.item.id, name: p.name, stats: p.stats, created_at: now, updated_at: now }
        end)
      end
      proposals.select { _1.status == 'known' }.each do |p|
        game_key = ItemGameKey.find_by!(key: p.key)
        game_key.update!(name: p.name, stats: p.stats || game_key.stats)
      end
    end
    added.size
  end

  # Records one ambiguous key for the item its name leads to.
  def record_one!(key)
    proposal = proposals.find { _1.key == key && _1.status == 'ambiguous' } or
      raise ArgumentError, "#{key} isn't an ambiguous key in this import"
    proposal.item.game_keys.create!(key: key, name: proposal.name, stats: proposal.stats)
  end

  private

  # { key => { name:, stats: } } for every key the export's recipes use.
  # Stats are a result's base stats; an ingredient's are what this recipe's
  # quantity adds, so they aren't the item's own.
  def seen_keys
    keys = {}
    @import.entries.each do |entry|
      gr = entry.game_recipe
      gr.results.each do |line|
        next unless line.key
        keys[line.key] = { name: line.name, stats: line.stats.presence }
      end
      gr.ingredients.each do |line|
        next unless line.key
        keys[line.key] ||= { name: line.name, stats: nil }
      end
    end
    keys
  end

  # Keys whose name the export also uses for another key of the same sort.
  def ambiguous_keys(keys)
    members = @import.game_groups.to_h { [ _1.key, _1.members.map(&:key).sort ] }
    keys.group_by { |key, seen| [ ItemGameKey.group_key?(key), seen[:name].downcase ] }
        .values
        .select { |same_name| same_name.size > 1 }
        .reject { |same_name| same_name.all? { |key, _| members[key] } &&
                              same_name.map { |key, _| members[key] }.uniq.one? }
        .flat_map { |same_name| same_name.map(&:first) }
        .to_set
  end

  def proposal(key, seen, recorded, items, ambiguous)
    named = items[@lookup.id_for(seen[:name])]
    build = ->(item, status, note = nil) { Proposal.new(key, seen[:name], seen[:stats], item, status, note) }

    if recorded
      holder = items[recorded.item_id]
      if named == holder
        build.(holder, 'known')
      elsif named.nil?
        build.(holder, 'renamed', "the site calls it #{holder.name}")
      else
        build.(holder, 'elsewhere', "the name is #{named.name} on the site")
      end
    elsif named.nil?
      build.(nil, 'unknown')
    elsif ambiguous.include?(key)
      build.(named, 'ambiguous', 'the export uses this name for more than one key')
    elsif !ItemGameKey.suits?(key, named)
      what = ItemGameKey.group_key?(key) ? 'a group slot' : 'an item'
      build.(named, 'unsuited', "#{what}, but the site has #{named.name} as #{named.kind_label}")
    else
      build.(named, 'record')
    end
  end

end
