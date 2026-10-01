# frozen_string_literal: true

# Puts a concrete Item into a group: an abstract Item standing for a set of
# items, the way the game uses names like "Metal Ingot" or "Copper or Iron
# Ingot". An item can belong to many groups. Groups are flat: they contain
# concrete items only, never other groups.
class ItemMembership < ApplicationRecord
  belongs_to :group,  class_name: 'Item', inverse_of: :member_memberships
  belongs_to :member, class_name: 'Item', inverse_of: :group_memberships

  validates :member_id, uniqueness: { scope: :group_id, message: 'is already in this group' }
  validate  :group_is_abstract
  validate  :member_is_concrete

  private

  def group_is_abstract
    errors.add(:group, 'must be an abstract item') if group && !group.abstract?
  end

  def member_is_concrete
    errors.add(:member, "can't itself be a group") if member&.abstract?
  end
end
