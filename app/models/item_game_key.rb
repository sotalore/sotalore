# frozen_string_literal: true

# One of the game's ids for an Item (see the item_game_keys migration):
#
#   item:<32 hex digits>  - a concrete item, or an archetype's base item
#                           ("Dagger" is a real item the game varies by material)
#   group:<number>        - a recipe slot taking any member of a group; maps to
#                           a group or category
#
# Keys come from recipe exports (see GameKeyRecorder), with the name the game
# last used and, for things recipes make, their base stats.
class ItemGameKey < ApplicationRecord
  FORMAT = /\A(item:\h{32}|group:-?\d+)\z/

  belongs_to :item, inverse_of: :game_keys

  validates :key, presence: true, format: { with: FORMAT }, uniqueness: true
  validates :name, presence: true
  validate  :item_kind_suits_key

  def self.group_key?(key)
    key.to_s.start_with?('group:')
  end

  def group_key?
    self.class.group_key?(key)
  end

  def to_s
    key.to_s
  end

  # Whether an item of this kind can hold this sort of key.
  def self.suits?(key, item)
    group_key?(key) ? (item.group? || item.category?) : (item.concrete? || item.archetype?)
  end

  private

  def item_kind_suits_key
    return unless item && key.present?
    unless self.class.suits?(key, item)
      errors.add(:key, "#{group_key? ? 'a group key' : 'an item key'} can't belong to #{item.kind_label}")
    end
  end
end
