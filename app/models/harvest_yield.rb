# frozen_string_literal: true

# What gathering from something can give: field dressing a Creature, or
# harvesting a GatheringNode. From finds imports; presence only.
class HarvestYield < ApplicationRecord
  SOURCES = %w[ Creature GatheringNode ].freeze

  belongs_to :source, polymorphic: true, optional: false
  belongs_to :item, optional: false

  validates :source_type, inclusion: { in: SOURCES }
end
