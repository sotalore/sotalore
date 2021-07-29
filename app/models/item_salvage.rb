class ItemSalvage < ApplicationRecord

  belongs_to :salvage_from, class_name: 'Item', counter_cache: :salvage_as_source_count
  belongs_to :salvage_to, class_name: 'Item', counter_cache: :salvage_as_result_count

  validates :salvage_from, :salvage_to, presence: true

  validate :cannot_salvage_into_self

  def cannot_salvage_into_self
    if salvage_from == salvage_to
      errors.add(:salvage_to, 'cannot be salvaged from itself')
    end
  end

  def salvage_to_name
    salvage_to.name if salvage_to
  end

end
