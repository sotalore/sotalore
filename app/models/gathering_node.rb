# frozen_string_literal: true

# Something gathered from in the game: a vein, plant or tree ("Copper Vein",
# "Cotton Plant", "Maple Tree"). Where it is (see SceneNode) and what
# harvesting it yields (see HarvestYield) come from finds imports. Which
# skill gathers from it is set by an editor; the finds file doesn't say.
#
# Finds imports can't always tell field dressing from harvesting: a creature
# nobody was seen fighting comes in as a node. An editor moves it to the
# creatures (#move_to_creatures!), and later imports file it there, since
# they treat any name the site knows as a creature as one.
class GatheringNode < ApplicationRecord
  serialize :gathering_skill, coder: CraftSkill

  has_many :scene_nodes, dependent: :delete_all
  has_many :scenes, -> { by_name }, through: :scene_nodes
  has_many :harvest_yields, as: :source, dependent: :delete_all
  has_many :yields, -> { by_name }, through: :harvest_yields, source: :item

  scope :by_name, -> { order(:name) }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validate :gathering_skill_is_for_nodes

  # The skills that gather from nodes; field dressing is from creatures.
  def self.skills
    CraftSkill.gathering.reject { _1.key == 'field_dressing' }
  end

  # Makes it a creature of the same name, living in its scenes and yielding
  # what it yields, and deletes it. Returns the creature.
  def move_to_creatures!
    transaction do
      creature = Creature.find_or_create_by!(name: name)
      creature.update!(notes: [ creature.notes, notes ].compact_blank.join("\n\n")) if notes.present?
      scene_nodes.each { SceneCreature.find_or_create_by!(scene_id: _1.scene_id, creature: creature) }
      harvest_yields.each { HarvestYield.find_or_create_by!(source: creature, item_id: _1.item_id) }
      destroy!
      creature
    end
  end

  def to_s
    name.to_s
  end

  private

  def gathering_skill_is_for_nodes
    if gathering_skill && !self.class.skills.include?(gathering_skill)
      errors.add(:gathering_skill, 'must be a gathering skill other than field dressing')
    end
  end
end
