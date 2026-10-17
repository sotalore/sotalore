# frozen_string_literal: true

# Something gathered from in the game: a vein, plant or tree ("Copper Vein",
# "Cotton Plant", "Maple Tree"). Where it is (see SceneNode) and what
# harvesting it yields (see HarvestYield) come from finds imports.
class GatheringNode < ApplicationRecord
  has_many :scene_nodes, dependent: :delete_all
  has_many :scenes, -> { by_name }, through: :scene_nodes
  has_many :harvest_yields, as: :source, dependent: :delete_all
  has_many :yields, -> { by_name }, through: :harvest_yields, source: :item

  scope :by_name, -> { order(:name) }

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def to_s
    name.to_s
  end
end
