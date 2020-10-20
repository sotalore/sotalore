class Item < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [ :name ]

  serialize :gathering_skill, CraftSkill

  enum use: %w[ unknown tool fuel component armor weapon decoration food potion house seed ], _prefix: 'use_is'
  enum source: %w[ unknown merchant gathering drop recipe ], _prefix: 'source_is'

  has_many :comments, as: :subject, dependent: :delete_all
  # TODO items shouldn't be deleteable if they are ingredients.
  has_many :ingredients, inverse_of: :item, dependent: :destroy
  has_many :recipe_uses, through: :ingredients, source: :recipe
  # TODO items shouldn't be deleteable if they are a result.
  has_many :results, inverse_of: :item, dependent: :destroy
  has_many :recipes, through: :results

  has_many   :instances, class_name: 'Item', inverse_of: :instance_of, foreign_key: 'instance_id'
  belongs_to :instance_of, class_name: 'Item', inverse_of: :instances, foreign_key: 'instance_id'

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
  before_validation :set_type_from_use, on: :create

  validates :name, presence: true, uniqueness: { case_sensitive: false, allow_blank: true }

  validate  :gathering_skill_is_gathering
  validates :price, absence: { if: ->(i) { i.abstract }, message: 'does not apply to abstract items' }

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

  def set_type_from_use
    if use == 'seed'
      self.type = 'Seed'
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
