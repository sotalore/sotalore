# frozen_string_literal: true

# Helps get items' kinds (see Item::ITEM_KINDS) right: gathers how each item
# is used by recipes and memberships, and flags likely misclassifications,
# with a suggested kind where the evidence points to one.
#
# Kinds were first guessed from the old abstract flag, and recipe imports
# create items before anyone knows what they stand for, so there's cleanup.
class ItemReview

  Issue = Data.define(:message, :suggest)

  # The game names what modifications act on like "Crafted Carpentry
  # Equipable" or "Crafted Two-handed Weapon".
  CATEGORY_NAME = /\ACrafted /i

  Row = Data.define(:item, :members, :groups, :ingredient_uses, :game_ingredient_uses,
                    :result_uses, :game_result_uses, :modified, :made_from_groups, :game_keys,
                    :issues) do
    def modified? = modified
    def issues? = issues.any?
  end

  FILTERS = %w[ abstract group archetype category suspect unkeyed recent ].freeze

  attr_reader :filter

  def initialize(filter: nil, issues_only: false, query: nil)
    @filter = filter.presence_in(FILTERS) || 'abstract'
    @filter = 'abstract' if @filter == 'recent' && !self.class.recent_since
    @issues_only = issues_only
    @query = query.presence
  end

  # Items created since recipe imports began, which are worth a look whatever
  # their kind.
  def self.recent_since
    RecipeImport.minimum(:created_at)
  end

  # { filter => item count }
  def self.counts
    by_kind = Item.group(:kind).count
    counts = {
      'abstract' => by_kind.except('concrete').values.sum,
      'group' => by_kind['group'].to_i,
      'archetype' => by_kind['archetype'].to_i,
      'category' => by_kind['category'].to_i,
      'suspect' => suspects.count,
      'unkeyed' => unkeyed.count,
    }
    counts['recent'] = Item.where(created_at: recent_since..).count if recent_since
    counts
  end

  # Concrete items that look like they stand for more than one thing.
  def self.suspects
    concrete = Item.kind_is_concrete
    concrete.where('items.name ILIKE ? OR items.name ILIKE ?', '% or %', 'Crafted %')
            .or(concrete.where(id: modified_item_ids))
  end

  # Items an active recipe uses or makes that have no game key (see
  # ItemGameKey) yet. Recipe imports record keys for the items their recipes
  # use, so these are items the game knows by another name, or recipes the
  # export didn't include. Groups and categories are left out: a group key
  # only belongs to one when a recipe slot takes it.
  def self.unkeyed
    active = Recipe.active.select(:id)
    used = Ingredient.where(recipe_id: active).select(:item_id)
    made = Result.where(recipe_id: active).select(:item_id)
    Item.where(kind: %i[ concrete archetype ])
        .where(id: used).or(Item.where(kind: %i[ concrete archetype ]).where(id: made))
        .where.not(id: ItemGameKey.select(:item_id))
  end

  # Ids of items a modification recipe takes and gives back.
  def self.modified_item_ids
    Recipe.modified_lines.select(:item_id)
  end

  # Rows for the filtered items, those with issues first.
  def rows
    @rows ||= begin
      items = scope.to_a
      rows = build_rows(items)
      rows = rows.select(&:issues?) if @issues_only
      rows.sort_by { |row| [ row.issues? ? 0 : 1, row.item.name.downcase ] }
    end
  end

  private

  def scope
    items =
      case @filter
      when 'abstract' then Item.abstract
      when 'suspect'  then self.class.suspects
      when 'unkeyed'  then self.class.unkeyed
      when 'recent'   then Item.where(created_at: self.class.recent_since..)
      else Item.where(kind: @filter)
      end
    items = items.where('items.name ILIKE ?', "%#{Item.sanitize_sql_like(@query)}%") if @query
    items
  end

  def build_rows(items)
    ids = items.map(&:id)
    members  = ItemMembership.where(group_id: ids).group(:group_id).count
    groups   = ItemMembership.where(member_id: ids).group(:member_id).count
    game_ingredient_uses = Ingredient.joins(:recipe).where(item_id: ids)
                                     .where.not(recipes: { game_id: nil }).group(:item_id).count
    game_result_uses = Result.joins(:recipe).where(item_id: ids)
                             .where.not(recipes: { game_id: nil }).group(:item_id).count
    modified = self.class.modified_item_ids.where(item_id: ids).distinct.pluck(:item_id).to_set
    game_keys = ItemGameKey.where(item_id: ids).group(:item_id).count
    made_from_groups = Result.where(item_id: ids)
                             .joins('JOIN ingredients ON ingredients.recipe_id = results.recipe_id')
                             .joins('JOIN items ON items.id = ingredients.item_id')
                             .where(items: { kind: Item.kinds[:group] })
                             .where('ingredients.item_id <> results.item_id')
                             .distinct.pluck('results.item_id', 'items.name')
                             .group_by(&:first).transform_values { |pairs| pairs.map(&:last).sort }

    items.map do |item|
      row = Row.new(item: item, members: members[item.id].to_i, groups: groups[item.id].to_i,
                    ingredient_uses: item.ingredients_count,
                    game_ingredient_uses: game_ingredient_uses[item.id].to_i,
                    result_uses: item.results_count,
                    game_result_uses: game_result_uses[item.id].to_i,
                    modified: modified.include?(item.id),
                    made_from_groups: made_from_groups.fetch(item.id, []),
                    game_keys: game_keys[item.id].to_i,
                    issues: [])
      row.with(issues: issues_for(row))
    end
  end

  def issues_for(row)
    item = row.item
    issues = []
    issue = ->(message, suggest = nil) { issues << Issue.new(message, suggest) }

    case item.kind
    when 'group'
      # A group is a material choice: a recipe calls for it, and any member
      # will do. Otherwise it's describing things, which is a category.
      if row.modified?
        issue.('A modification recipe takes it and gives it back', 'category')
      elsif row.game_result_uses.positive?
        issue.("A game recipe makes it, and the game doesn't make groups", 'archetype')
      elsif row.ingredient_uses.zero?
        issue.('No recipe calls for it, so it isn\'t a material choice', 'category')
      end
      if row.members.zero? && issues.none?(&:suggest) && item.name.match?(CATEGORY_NAME)
        issue.('No members yet, and the name reads like a category', 'category')
      elsif row.members.zero?
        issue.('No members yet')
      end
    when 'archetype'
      if row.modified?
        issue.('A modification recipe takes it and gives it back', 'category')
      elsif row.result_uses.zero?
        issue.('No recipe makes it', 'group')
      end
    when 'concrete'
      issue.('The name looks like a set of items', 'group') if item.name.match?(/ or /i)
      if row.modified?
        issue.('A modification recipe takes it: a category, unless it upgrades this one item',
               'category')
      elsif item.name.match?(CATEGORY_NAME)
        issue.('The name reads like a category', 'category')
      end
    end
    issue.('Has a price, which abstract items can\'t') if item.abstract? && item.price
    issues
  end

end
