# frozen_string_literal: true

# A site-curated way of grouping items, to answer questions like "what are
# the heavy armors?": "Potions", "Poison Potions", "Fortified Leather Armor".
# Unlike the game's groups and categories (see Item::ITEM_KINDS), nothing in
# the game uses these; they're for browsing.
#
# A collection lists concrete items and archetypes, and can sit inside other
# collections, more than one at a time: "Fortified Leather Armor" is in both
# "Light Armor" and "Leather Armor". Its items include those of everything
# inside it, however deep (see #all_items).
class Collection < ApplicationRecord
  has_many :collection_items, dependent: :delete_all, inverse_of: :collection
  has_many :items, -> { order(:name) }, through: :collection_items

  has_many :child_links, class_name: 'CollectionLink', foreign_key: :parent_id,
           dependent: :delete_all, inverse_of: :parent
  has_many :children, -> { order(:name) }, through: :child_links
  has_many :parent_links, class_name: 'CollectionLink', foreign_key: :child_id,
           dependent: :delete_all, inverse_of: :child
  has_many :parents, -> { order(:name) }, through: :parent_links

  scope :by_name, -> { order(:name) }

  # Collections inside no other.
  scope :top_level, -> { where.not(id: CollectionLink.select(:child_id)) }

  before_validation { self.description = nil if description.blank? }

  validates :name, presence: true, uniqueness: true

  def to_s = name.to_s

  # { parent id => [ child ids ] } for every link: there are few
  # collections, so walking them in Ruby is simplest.
  def self.children_map
    CollectionLink.pluck(:parent_id, :child_id).group_by(&:first).transform_values { _1.map(&:last) }
  end

  def self.parents_map
    CollectionLink.pluck(:child_id, :parent_id).group_by(&:first).transform_values { _1.map(&:last) }
  end

  # Everything inside this one, however deep.
  def descendant_ids(map = self.class.children_map) = walk(map)

  # Everything this one is inside, however far up.
  def ancestor_ids(map = self.class.parents_map) = walk(map)

  def ancestors = Collection.where(id: ancestor_ids).by_name

  # Its items and those of everything inside it, each with the collections
  # it's listed in: { item => [ collections ] }, by item name.
  def all_items
    CollectionItem.where(collection_id: [ id, *descendant_ids ]).includes(:item, :collection)
                  .group_by(&:item).transform_values { |rows| rows.map(&:collection).sort_by(&:name) }
                  .sort_by { |item, _| item.name.downcase }.to_h
  end

  # Collections that could hold this one: not itself or anything inside it.
  def possible_parents
    Collection.where.not(id: [ id, *descendant_ids ].compact).by_name
  end

  private

  def walk(map)
    return [] unless persisted?
    seen = Set.new
    queue = Array(map[id])
    while (next_id = queue.shift)
      next unless seen.add?(next_id)
      queue.concat(Array(map[next_id]))
    end
    seen.to_a
  end
end
