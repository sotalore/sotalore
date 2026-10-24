# frozen_string_literal: true

# Lists an item in a Collection: a concrete item, or an archetype ("Fortified
# Leather Boots"). Groups and categories are the game's own ways of grouping,
# so they're never listed; list their members instead.
class CollectionItem < ApplicationRecord
  belongs_to :collection, inverse_of: :collection_items
  belongs_to :item

  validates :item_id, uniqueness: { scope: :collection_id, message: 'is already in this collection' }
  validate  :item_is_concrete_or_archetype

  private

  def item_is_concrete_or_archetype
    return if item.nil? || item.concrete? || item.archetype?
    errors.add(:item, "must be a concrete item or an archetype, not #{item.kind_label}")
  end
end
