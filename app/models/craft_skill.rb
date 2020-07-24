# frozen-string-literal: true

class CraftSkill
  include ActiveModel::Model

  attr_reader :key, :category_key

  ALL = []
  MAP = {}

  PRIMARY_TOOLS = {
    'field_dressing' => 'Skinning Knife',
    'fishing'        => 'Fishing Rod',
    'foraging'       => 'Sickle',
    'forestry'       => 'Harvesting Axe',
    'mining'         => 'Pickaxe',
    'agriculture'    => 'Hoe',
    'butchery'       => 'Cleaver',
    'milling'        => 'Cubit Measure',
    'smelting'       => 'Smelting Tongs',
    'tanning'        => 'Tanning Knife',
    'textiles'       => 'Loom Shuttle',
    'alchemy'        => 'Mortar and Pestle',
    'blacksmithing'  => 'Smithing Hammer',
    'carpentry'      => 'Carpentry Hammer',
    'cooking'        => 'Cooking Pot',
    'tailoring'      => 'Tailoring Scissors',
  }

  def initialize(key, category_key)
    @key, @category_key = key, category_key
    ALL << self
    MAP[key] = self
  end

  def self.find(key)
    MAP[key]
  end

  def self.load(str)
    find(str)
  end

  def self.dump(cs)
    case cs
    when String
      cs
    when CraftSkill
      cs.key
    else
      raise "Cannot coerce #{cs.inspect} into a CraftSkill#key"
    end
  end

  def self.gathering
    @gathering ||= ALL.select(&:gathering?)
  end

  new('field_dressing', 'gathering')
  new('fishing', 'gathering')
  new('foraging', 'gathering')
  new('forestry', 'gathering')
  new('mining', 'gathering')

  new('agriculture', 'refining')
  new('butchery', 'refining')
  new('milling', 'refining')
  new('smelting', 'refining')
  new('tanning', 'refining')
  new('textiles', 'refining')

  new('alchemy', 'production')
  new('blacksmithing', 'production')
  new('carpentry', 'production')
  new('cooking', 'production')
  new('tailoring', 'production')

  ALL.freeze
  MAP.freeze

  def name
    @name ||= key.titleize
  end
  alias_method :to_s, :name

  def id
    key
  end

  def icon_name
    "craft_#{key}_small.png"
  end

  def to_param
    key
  end

  def category
    @categry ||= category_key.titleize
  end

  def gathering?
    category_key == 'gathering'
  end

  def has_recipes?
    !gathering?
  end
  WITH_RECIPES = ALL.select(&:has_recipes?).freeze

  def primary_tool
    PRIMARY_TOOLS.fetch(key)
  end

end
