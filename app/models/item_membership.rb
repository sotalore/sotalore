# frozen_string_literal: true

# Puts a concrete Item into a group or category (the group side here means
# either). A group's members are the complete set it stands for, the way the
# game uses names like "Metal Ingot" or "Copper or Iron Ingot"; a category's
# members are just examples of what qualifies. An item can belong to many of
# either. Both are flat: members are concrete items only.
class ItemMembership < ApplicationRecord
  belongs_to :group,  class_name: 'Item', inverse_of: :member_memberships
  belongs_to :member, class_name: 'Item', inverse_of: :group_memberships

  validates :member_id, uniqueness: { scope: :group_id, message: 'is already in this group' }
  validate  :group_is_a_group
  validate  :member_is_concrete

  private

  def group_is_a_group
    errors.add(:group, 'must be a group or category') if group && !group.can_have_members?
  end

  def member_is_concrete
    errors.add(:member, "must be a concrete item, not #{member.kind_label}") if member&.abstract?
  end
end
