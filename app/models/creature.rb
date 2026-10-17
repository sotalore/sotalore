# frozen_string_literal: true

# A creature that lives in the game, as the finds file names it: by the name
# combat prints, which is all the game gives (no id or type), so creatures of
# one name are one creature. Where it lives (see SceneCreature) and what
# field dressing it yields (see HarvestYield) come from finds imports.
class Creature < ApplicationRecord
  has_many :scene_creatures, dependent: :delete_all
  has_many :scenes, -> { by_name }, through: :scene_creatures
  has_many :harvest_yields, as: :source, dependent: :delete_all
  has_many :yields, -> { by_name }, through: :harvest_yields, source: :item

  scope :by_name, -> { order(:name) }

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def to_s
    name.to_s
  end
end
