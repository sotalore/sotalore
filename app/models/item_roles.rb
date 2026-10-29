# frozen_string_literal: true

# What an item is used for, read from the recipes rather than the item's
# stored +use+ (whose old "component" only ever meant some recipe took it). A
# recipe that asks for a group or category the item is in ("Metal Ingot",
# "Wooden Board") takes it too. An item can have several roles:
#
#   refining   - refining recipes take it (smelting, milling, ...)
#   production - production recipes take it (blacksmithing, cooking, ...)
#   tool       - the game's tooltip says "Tool"
class ItemRoles

  KINDS = %i[ refining production tool ].freeze

  # Recipes that take it as one of +group+'s items, for each group it's in.
  Through = Data.define(:group, :count)

  attr_reader :item

  def initialize(item)
    @item = item
  end

  # The kinds that apply, in KINDS order.
  def kinds
    KINDS.select { |kind| public_send(:"#{kind}?") }
  end

  def refining? = refining_counts.any?
  def production? = production_counts.any?

  # Whether a captured tooltip says it's a tool.
  def tool?
    item.game_keys.any? { _1.catalog&.dig('details', 'tool') }
  end

  # { CraftSkill => how many refining recipes take it }, most first.
  def refining_counts = counts('refining')

  # { CraftSkill => how many production recipes take it }, most first.
  def production_counts = counts('production')

  # The recipes that take it, directly or through a group or category it's
  # in; not retired.
  def recipes
    @recipes ||= Recipe.where(id: Ingredient.where(item_id: taking_ids).select(:recipe_id), retired_at: nil).to_a
  end

  # How many recipes take it through each group or category it's in.
  def through
    @through ||= begin
      counts = Ingredient.joins(:recipe).where(item_id: taking_ids - [ item.id ], recipes: { retired_at: nil }).group(:item_id).count
      Item.where(id: counts.keys).order(:name).map { Through.new(_1, counts[_1.id]) }
    end
  end

  private

  # The item, and the groups and categories it's in.
  def taking_ids
    @taking_ids ||= [ item.id ] + item.group_memberships.pluck(:group_id)
  end

  def counts(category)
    recipes.map(&:craft_skill).select { _1.category_key == category }.tally.sort_by { |skill, n| [ -n, skill.name ] }.to_h
  end
end
