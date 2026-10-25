# frozen_string_literal: true

# What kind of gear the game says an item is, from its tooltip's type line
# (the item catalog's details.types; see sl-lua/EXPORT-FORMAT.md):
#
#   "Leather Light Armor (Head)"   armor: leather, light, head
#   "Universal Heavy Armor (Head)" armor: any material, heavy, head
#   "Heavy Shield"                 shield: heavy
#   "Two-handed Sword - Bladed"    weapon: Two-handed Sword, bladed
#
# Read from the game keys' stored tooltips, so it's only known for items
# someone hovered with capture on. Crafted pieces' tooltips aren't kept with
# their types, so archetypes rarely have one; collections cover those.
class GearType

  ARMOR  = /\A(?<material>\w+) (?<weight>Light|Heavy) Armor \((?<slot>Head|Torso|Hands|Legs|Feet)\)\z/
  SHIELD = /\A(?<weight>Light|Heavy) Shield\z/
  WEAPON = /\A(?<weapon>.+) - (?<damage>Bladed|Bludgeon|Polearm|Ranged)\z/

  KINDS     = %w[ armor shield weapon ].freeze
  WEIGHTS   = %w[ light heavy ].freeze
  MATERIALS = %w[ cloth leather chain plate universal ].freeze
  SLOTS     = %w[ head torso hands legs feet ].freeze
  DAMAGES   = %w[ bladed bludgeon polearm ranged ].freeze

  # The facets a list of gear can be filtered by, with their values.
  FACETS = { kind: KINDS, weight: WEIGHTS, material: MATERIALS, slot: SLOTS, damage: DAMAGES }.freeze

  attr_reader :line, :kind, :weight, :material, :slot, :weapon, :damage

  # The first type line in +lines+ that names gear, or nil.
  def self.parse(lines)
    Array(lines).each do |line|
      type = from_line(line.to_s.strip)
      return type if type
    end
    nil
  end

  def self.from_line(line)
    if (m = ARMOR.match(line))
      new(line, kind: 'armor', weight: m[:weight].downcase, material: m[:material].downcase, slot: m[:slot].downcase)
    elsif (m = SHIELD.match(line))
      new(line, kind: 'shield', weight: m[:weight].downcase)
    elsif (m = WEAPON.match(line))
      new(line, kind: 'weapon', weapon: m[:weapon], damage: m[:damage].downcase)
    end
  end

  # The gear type of +item+, from its game keys' tooltips.
  def self.for_item(item)
    parse(item.game_keys.flat_map { |key| Array(key.catalog&.dig('details', 'types')) })
  end

  # { item => GearType } for every item whose tooltip names gear, by name.
  def self.items
    ItemGameKey.where("catalog -> 'details' -> 'types' IS NOT NULL").includes(:item)
               .group_by(&:item)
               .filter_map { |item, keys| (type = parse(keys.flat_map { Array(_1.catalog.dig('details', 'types')) })) && [ item, type ] }
               .sort_by { |item, _| item.name.downcase }.to_h
  end

  def initialize(line, kind:, weight: nil, material: nil, slot: nil, weapon: nil, damage: nil)
    @line = line
    @kind = kind
    @weight = weight
    @material = material
    @slot = slot
    @weapon = weapon
    @damage = damage
  end

  # The item use it implies (see Item::ITEM_USES): shields are armor.
  def use = kind == 'weapon' ? 'weapon' : 'armor'

  # Whether it has every facet in +filters+ ({ weight: 'heavy', ... }).
  def matches?(filters)
    filters.all? { |facet, value| public_send(facet) == value }
  end

  def to_s = line
end
