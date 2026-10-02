class Recipe < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [ :name ]
  include RecipeKey
  include Verifiable

  serialize :craft_skill, coder: CraftSkill

  enum :teachable, [ :teachable, :re_teachable, :not_teachable ]

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
  scope :active,  -> { where(retired_at: nil) }

  # Template recipes make a group (an abstract item). Some are curated on the
  # site to show the general recipe ("Dagger Blade"), where the game only has
  # the concrete recipes making each member ("Iron Dagger Blade", ...). Others
  # are game recipes whose result depends on the ingredients ("Dagger" takes
  # any "Dagger Blade"); those have a game_id.
  scope :templates, -> {
    where(id: Result.joins(:item).merge(Item.abstract).select(:recipe_id))
  }
  scope :concrete, -> {
    where.not(id: Result.joins(:item).merge(Item.abstract).select(:recipe_id))
  }
  scope :retired, -> { where.not(retired_at: nil) }

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
  validates :game_id, uniqueness: true, allow_nil: true

  def self.find_by_name(name)
    return none if name.blank?
    where("lower(name) = ?", name.downcase).first
  end

  def to_s
    name.to_s
  end

  # Retired recipes are ones the game no longer exports. They're kept (users
  # may have saved them) but hidden from the default listing.
  def retired?
    retired_at.present?
  end

  def retire!
    update_columns(retired_at: Time.current) unless retired?
  end

  def unretire!
    update_columns(retired_at: nil) if retired?
  end

  def template?
    results.any? { |r| r.item.abstract? }
  end

  # For a template: the concrete recipes making members of its group(s).
  def variants
    group_ids = results.map(&:item).select(&:abstract?).map(&:id)
    return Recipe.none if group_ids.empty?
    member_ids = ItemMembership.where(group_id: group_ids).select(:member_id)
    Recipe.where(id: Result.where(item_id: member_ids).select(:recipe_id)).where.not(id: id)
  end

  # For a concrete recipe: the groups its results belong to.
  def result_groups
    Item.where(id: ItemMembership.where(member_id: results.map(&:item_id)).select(:group_id)).by_name
  end

  # For a concrete recipe: the template recipes for the groups it makes a
  # member of.
  def templates
    Recipe.where(id: Result.where(item_id: result_groups.select(:id)).select(:recipe_id))
          .where.not(id: id)
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
