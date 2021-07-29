class Item < ApplicationRecord

  self.ignored_columns = [:type]

  include PgSearch::Model
  multisearchable against: [ :name ]

  serialize :gathering_skill, CraftSkill

  ITEM_USES = {
    unknown: 0,
    armor: 4,
    artifact: 17,
    component: 3,
    decoration: 6,
    dye: 13,
    'fishing-bait': 12,
    food: 7,
    fuel: 2,
    house: 9,
    instrument: 14,
    pattern: 15,
    'pet-food': 11,
    potion: 8,
    scroll: 16,
    'socketable-gem': 18,
    'socketable-jewel': 19,
    'socketable-imbued-gem': 20,
    'socketable-imbued-jewel': 21,
    seed: 10,
    tool: 1,
    weapon: 5,
  }

  enum use: ITEM_USES, _prefix: 'use_is'
  enum source: %w[ unknown merchant gathering drop recipe ], _prefix: 'source_is'

  # TYPE DATA
  store_accessor :type_data, :yield
  store_accessor :type_data, :buff_slots_used

  has_many :comments, as: :subject, dependent: :delete_all
  # TODO items shouldn't be deleteable if they are ingredients.
  has_many :ingredients, inverse_of: :item, dependent: :destroy
  has_many :recipe_uses, through: :ingredients, source: :recipe
  # TODO items shouldn't be deleteable if they are a result.
  has_many :results, inverse_of: :item, dependent: :destroy
  has_many :recipes, through: :results

  has_many   :instances, class_name: 'Item', inverse_of: :instance_of, foreign_key: 'instance_id'
  belongs_to :instance_of, class_name: 'Item', inverse_of: :instances, foreign_key: 'instance_id'

  has_many :item_salvages_as_source, class_name: 'ItemSalvage', foreign_key: 'salvage_from_id', dependent: :delete_all
  has_many :item_salvages_as_result, class_name: 'ItemSalvage', foreign_key: 'salvage_to_id', dependent: :delete_all

  has_many :salvages_to, through: :item_salvages_as_source, source: :salvage_to
  has_many :salvages_from, through: :item_salvages_as_result, source: :salvage_from

  scope :with_data, -> {
    eager_load(:ingredients, :results)
    .preload(ingredients: { recipe: :results })
    .preload(results: :item)
  }

  scope :by_name, -> { order('lower(name)') }

  def self.find_by_name(name)
    name = name.blank? ? nil : name.downcase
    where("lower(name) = ?", name)
  end

  before_validation :nilify_blanks

  validates :name, presence: true, uniqueness: { case_sensitive: false, allow_blank: true }

  validate  :gathering_skill_is_gathering
  validates :price, absence: { if: ->(i) { i.abstract }, message: 'does not apply to abstract items' }

  # TYPE DATA VALIDATIONS
  validates :yield, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :buff_slots_used, numericality: { only_integer: true, greater_than: 0, less_than: 4 }, allow_nil: true

  before_destroy  :cannot_be_deleted_if_ingredient, prepend: true
  before_destroy  :destroy_recipes_with_identical_names, prepend: true

  def to_s
    name.to_s
  end

  def craftable?
    results_count > 0
  end

  def component?
    ingredients_count > 0
  end

  def gatherable?
    !!gathering_skill
  end

  def <=>(other)
    unless Item === other
      raise ArgumentError.new("Cannot compare an Item to a #{other.class}")
    end
    if use_is_tool? && !other.use_is_tool?
      -1
    elsif other.use_is_tool?
      1
    elsif use_is_fuel? && !other.use_is_fuel?
      -1
    elsif other.use_is_fuel?
      1
    else
      name.downcase <=> other.name.downcase
    end
  end

  private
  def gathering_skill_is_gathering
    if gathering_skill && !gathering_skill.gathering?
      errors.add(:gathering_skill, 'must be a gathering skill')
    end
  end

  def nilify_blanks
    self.type_data = (type_data || {}).reject { |_,v| v.blank? }
    self.notes = nil if notes.blank?
    self.effects = nil if effects.blank?
  end

  def cannot_be_deleted_if_ingredient
    throw :abort if ingredients.any?
  end

  def destroy_recipes_with_identical_names
    recipes.where("lower(name) = ?", name.downcase).each(&:destroy)
  end

end
