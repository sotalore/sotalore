# frozen_string_literal: true

# Puts one Collection inside another. A collection can be inside several,
# but never inside itself, however far down.
class CollectionLink < ApplicationRecord
  belongs_to :parent, class_name: 'Collection', inverse_of: :child_links
  belongs_to :child,  class_name: 'Collection', inverse_of: :parent_links

  validates :child_id, uniqueness: { scope: :parent_id, message: 'is already inside this collection' }
  validate  :no_loops

  private

  def no_loops
    return unless parent && child
    if parent == child || parent.ancestor_ids.include?(child.id)
      errors.add(:base, "#{child.name} can't be inside #{parent.name}: #{parent.name} is inside it")
    end
  end
end
