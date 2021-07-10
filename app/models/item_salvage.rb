class ItemSalvage < ApplicationRecord

  belongs_to :salvage_source, class_name: 'Item', counter_cache: :salvage_source_count
  belongs_to :salvage_result, class_name: 'Item', counter_cache: :salvage_result_count

  validate :cannot_salvage_into_self

  def cannot_salvage_into_self
    if salvage_source == salvage_result
      errors.add(:salvage_result, 'cannot be the salvage source')
    end
  end
end