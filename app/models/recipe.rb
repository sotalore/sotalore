class Recipe < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [ :name ]
  include RecipeKey

  serialize :craft_skill, CraftSkill

  enum teachable: [ :teachable, :re_teachable, :not_teachable ]

  pg_search_scope :search_by_name, against: :name,
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.1 }
                  }

  has_many :comments, as: :subject, dependent: :delete_all
  has_many :ingredients, -> { eager_load(:item) },
           autosave: true, inverse_of: :recipe, dependent: :destroy
  has_many :results, -> { eager_load(:item) },
           autosave: true, inverse_of: :recipe, dependent: :destroy

  has_many :user_recipes, dependent: :delete_all, inverse_of: :recipe

  scope :by_name, -> { order(Arel.sql('lower(name)')) }

  def self.random(count=1)
    ids = Recipe.all.pluck(:id).sample(count)
    where(id: ids)
  end

  before_validation :set_recipe_key

  validates :name, presence: true
  validates :craft_skill, presence: true
  validates :craft_skill, inclusion: {
              in: CraftSkill::WITH_RECIPES,
              allow_blank: true
            }
  validates :recipe_key, presence: true, uniqueness: true

  def self.find_by_name(name)
    return none if name.blank?
    where("lower(name) = ?", name.downcase).first
  end

  def to_s
    name.to_s
  end

  def fuel_cost
    ingredients.map(&:fuel_price).compact.sum
  end

  def work_list(count=nil)
    WorkList.new(self, count)
  end

  def set_recipe_key
    self.recipe_key = generate_recipe_key
  end

end
