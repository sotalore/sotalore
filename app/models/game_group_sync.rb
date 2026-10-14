# frozen_string_literal: true

# Compares the groups in a recipe export (see GameGroup) with the site items
# holding their keys (see ItemGameKey), and brings members across:
#
# * a site group gets the game's members, with any the site doesn't know
#   created as concrete items (they're often looted, not crafted). When the
#   game lists them all, site members it doesn't list can be removed too
# * a site category gets the known members as examples; its list is never
#   expected to be complete, so nothing is created or removed
#
# Members are matched by key, or by name (recording the key) when the key
# isn't recorded yet. A member whose name is a site item that can't be a
# member (a group, or an archetype in a group; categories can list
# archetypes) is a conflict for an admin to sort out.
class GameGroupSync

  # A game group and what syncing it would do. +add+ is [ [Item, [keys]] ]
  # of known items to add (keys to record with them), +create+ is
  # [ [name, [keys]] ] of unknown members, +remove+ is [Item] of site members
  # the game doesn't list (only when it lists all), and +conflicts+ is
  # [ [name, Item] ].
  Row = Data.define(:game_group, :item, :add, :create, :remove, :conflicts) do
    def key = game_group.key
    def mapped? = !item.nil?
    def changes? = add.any? || create.any? || remove.any?

    def status
      if !mapped? then 'unmapped'
      elsif changes? || conflicts.any? then 'differs'
      else 'in_sync'
      end
    end
  end

  STATUSES = %w[ differs unmapped in_sync ].freeze

  def initialize(import, user, lookup: ItemLookup.new)
    @import = import
    @user = user
    @lookup = lookup
  end

  def rows
    @rows ||= begin
      groups = @import.game_groups
      holders = ItemGameKey.where(key: groups.map(&:key)).includes(item: :members).index_by(&:key)
      members = groups.flat_map(&:members)
      member_ids = members.filter_map { @lookup.id_for(_1) } + members.filter_map { @lookup.id_for(_1.name) }
      @items = Item.where(id: member_ids).index_by(&:id)
      groups.map { row_for(_1, holders[_1.key]&.item) }
            .sort_by { |row| [ STATUSES.index(row.status), row.game_group.name.downcase, row.key ] }
    end
  end

  def row(key)
    rows.find { _1.key == key } or raise ArgumentError, "#{key} isn't a group in this import"
  end

  # Adds the members (or examples) the game lists that the site item lacks,
  # creating unknown ones for a group. Returns how many were added.
  def add!(key)
    row = row(key)
    raise ArgumentError, "#{row.game_group.name} isn't on the site yet" unless row.mapped?
    ItemMembership.transaction do
      created = row.create.map do |name, keys|
        item = Item.create!(name: name, kind: :concrete)
        keys.each { item.game_keys.create!(key: _1, name: name) }
        item
      end
      row.add.each do |item, keys|
        keys.each { item.game_keys.create!(key: _1, name: item.name) }
      end
      (row.add.map(&:first) + created).each do |member|
        membership = ItemMembership.create!(group: row.item, member: member)
        RevisionRecorder.membership(membership, @user, :added)
      end
      row.add.size + created.size
    end
  end

  # Removes the site members a complete game group doesn't list. Returns how
  # many were removed.
  def remove!(key)
    row = row(key)
    ItemMembership.transaction do
      row.remove.each do |member|
        membership = ItemMembership.find_by!(group: row.item, member: member)
        membership.destroy!
        RevisionRecorder.membership(membership, @user, :removed)
      end
    end
    row.remove.size
  end

  private

  def row_for(game_group, item)
    return Row.new(game_group, nil, [], [], [], []) unless item

    current = item.members.to_set
    add = Hash.new { |h, k| h[k] = [] }
    create = Hash.new { |h, k| h[k] = [] }
    conflicts = []
    listed = Set.new

    game_group.members.each do |member|
      site = @items[@lookup.id_for(member)]
      if site.nil? && (named = @items[@lookup.id_for(member.name)])
        conflicts << [ member.name, named ]
      elsif site.nil?
        create[member.name] << member.key if item.group?
      elsif !(site.concrete? || (site.archetype? && item.category?))
        conflicts << [ member.name, site ]
      else
        listed << site
        next if current.include?(site)
        keys = add[site]
        keys << member.key unless @lookup.id_for_key(member.key)
      end
    end

    remove = item.group? && game_group.complete? ? (current - listed).sort_by(&:name) : []
    Row.new(game_group, item, add.to_a.sort_by { _1.first.name }, create.to_a.sort_by(&:first),
            remove, conflicts.uniq.sort_by(&:first))
  end

end
