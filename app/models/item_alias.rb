# frozen_string_literal: true

# An alternate name for an Item, usually a name the item used to have before
# it was renamed to match the game. Lets game exports that use the alias
# still resolve to the item.
class ItemAlias < ApplicationRecord
  belongs_to :item, inverse_of: :aliases

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validate  :name_is_not_an_item_name

  def to_s
    name.to_s
  end

  private

  def name_is_not_an_item_name
    return if name.blank?
    if Item.where.not(id: item_id).find_by_name(name).exists?
      errors.add(:name, 'is already the name of another item')
    end
  end
end
