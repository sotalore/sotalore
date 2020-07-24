class Scene < ApplicationRecord

  LEVELS = {
    'Tier 0' => 0,
    'Tier 1' => 1,
    'Tier 2' => 2,
    'Tier 3' => 3,
    'Tier 4' => 4,
    'Tier 5' => 5,
    'Tier 6' => 6,
    'Tier 7' => 7,
    'Tier 8' => 8,
    'Tier 9' => 9,
    'Tier 10' => 10,
  }.freeze
  LEVEL_NAMES = LEVELS.invert.freeze

  SCENE_TYPES = {
    'Overworld'           => 0,
    'Adventure'           => 1,
    'Control Point'       => 2,
    'Dungeon'             => 3,
    'Mine'                => 4,
    'Underground Passage' => 5,
    'NPC Town'            => 6,
    'Player Owned Town (POT)' => 7,
    'Player Run Town (PRT)' => 8,
  }.freeze
  SCENE_TYPE_NAMES = SCENE_TYPES.invert.freeze

  REGIONS = {
    'Hidden Vale'     => 1,
    'Norgard'         => 2,
    'North Paladis'   => 3,
    'Regalis'         => 4,
    'Drachvald'       => 5,
    'Verdantis'       => 6,
    'Forsaken Vale'   => 7,
    'South Paladis'   => 8,
    'Midmaer'         => 9,
    'Grunvald'        => 10,
    'Longfall'        => 11,
    'Elysium'         => 12,
    'Quel'            => 13,
    'Perennial Coast' => 14,
  }.freeze
  REGION_NAMES = REGIONS.invert.freeze

  belongs_to :parent, class_name: 'Scene'
  has_many :comments, as: :subject, dependent: :delete_all

  scope :by_name, -> { order(Arel.sql('lower(name)')) }
  scope :by_name_overworld_first, -> { order(Arel.sql('scene_type_id != 0, lower(name)')) }

  validates :name, presence: true, uniqueness: { ignore_case: true }
  # Can only have one top-level
  validates :parent_id, uniqueness: true, if: ->(s) { s.parent_id.nil? }
  validates :sota_map_id, uniqueness: true, allow_nil: true
  validates :sota_map_parent_poi_id, uniqueness: true, allow_nil: true
  validate  :parent_is_not_self

  def to_s
    name
  end

  def overworld?
    parent_id.nil?
  end

  def region
    REGION_NAMES[region_id]
  end

  def scene_type
    SCENE_TYPE_NAMES[scene_type_id]
  end

  def level
    LEVEL_NAMES[level_id]
  end

  def has_parent_location_info?
    sota_map_parent_poi_id.present? && parent && parent.sota_map_id.present?
  end

  def sota_map_in_parent_url
    "https://www.shroudoftheavatar.com/map/?map_id=#{parent.sota_map_id}&poi_id=#{sota_map_parent_poi_id}&openPopup=true&z=3"
  end

  def sota_map_url
    "https://www.shroudoftheavatar.com/map/?map_id=#{sota_map_id}"
  end

  def parent_is_not_self
    if parent_id && parent_id == self.id
      errors.add(:parent_id, 'cannot be this scene')
    end
  end

end
