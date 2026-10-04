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

  scope :retired, -> { where.not(retired_at: nil) }

  # What a recipe is, from what it makes (see Item::ITEM_KINDS), first that
  # applies:
  #
  #   modification - gives back an item it takes, without making more of it
  #                  ("Masterwork Carpentry Upgrade" takes and gives back a
  #                  "Crafted Carpentry Equipable"). "Clone Jar of Yeast
  #                  Culture" gives back more Yeast than it takes, so it isn't.
  #   template     - makes a group. Curated on the site to show the general
  #                  recipe ("Dagger Blade"); the game only has the recipes
  #                  making each member ("Iron Dagger Blade", ...).
  #   archetype    - makes an archetype (or category): which one you get
  #                  depends on the ingredients ("Dagger" takes any "Dagger
  #                  Blade").
  #   concrete     - makes concrete items.
  KINDS = %w[ modification template archetype concrete ].freeze

  # The ingredient lines a recipe gives back (no more of than it takes).
  def self.modified_lines
    Ingredient.joins('JOIN results ON results.recipe_id = ingredients.recipe_id ' \
                     'AND results.item_id = ingredients.item_id AND results.count <= ingredients.count')
  end

  scope :modifications, -> { where(id: modified_lines.select(:recipe_id)) }
  scope :templates, -> {
    where(id: Result.joins(:item).merge(Item.kind_is_group).select(:recipe_id)).where.not(id: modifications)
  }
  scope :archetypes, -> {
    where(id: Result.joins(:item).where(items: { kind: Item.kinds.values_at('archetype', 'category') })
                    .select(:recipe_id))
      .where.not(id: modifications).where.not(id: templates)
  }
  scope :concrete, -> {
    where.not(id: Result.joins(:item).merge(Item.abstract).select(:recipe_id)).where.not(id: modifications)
  }

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

  def kind
    if modification?
      'modification'
    elsif results.any? { |r| r.item.group? }
      'template'
    elsif results.any? { |r| r.item.abstract? }
      'archetype'
    else
      'concrete'
    end
  end

  def modification? = modified_items.any?
  def template?     = kind == 'template'
  def archetype?    = kind == 'archetype'

  # The items this recipe takes and gives back (see KINDS).
  def modified_items
    taken = ingredients.to_h { |i| [ i.item_id, i.count.to_i ] }
    results.select { |r| taken[r.item_id] && r.count.to_i <= taken[r.item_id] }.map(&:item)
  end

  # For a template: the concrete recipes making members of its group(s).
  def variants
    group_ids = results.map(&:item).select(&:group?).map(&:id)
    return Recipe.none if group_ids.empty?
    member_ids = ItemMembership.where(group_id: group_ids).select(:member_id)
    Recipe.where(id: Result.where(item_id: member_ids).select(:recipe_id)).where.not(id: id)
  end

  # For a concrete recipe: the groups (not categories) its results belong to.
  def result_groups
    Item.kind_is_group.where(id: ItemMembership.where(member_id: results.map(&:item_id)).select(:group_id))
        .by_name
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
