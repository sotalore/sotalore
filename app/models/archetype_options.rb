# frozen_string_literal: true

# The choices an archetype recipe offers ("Longsword": any Longsword Blade
# and any Metal Hilt). Which longsword you get depends on them, and each
# chosen component brings its own crafting bonus (see Item#crafting_bonus),
# so the game has no item for each
# combination and the site keeps none: they're worked out here, one slot per
# group the recipe takes, with what each choice costs the user (see
# RecipeCost).
#
#   options = ArchetypeOptions.new(recipe, RecipeCost.new(recipe, Current.user))
#   options.combinations # => 72
class ArchetypeOptions

  Choice = Data.define(:item, :cost, :count) do
    def total = cost && cost.unit * count
  end

  Slot = Data.define(:group, :count, :choices) do
    def cheapest = choices.select(&:total).min_by(&:total)
  end

  attr_reader :recipe

  def initialize(recipe, cost)
    @recipe = recipe
    @cost = cost
  end

  def slots
    @slots ||= recipe.ingredients.map { [ _1.item, _1.count ] }.select { |item, _| item.group? }
                     .sort_by { |item, _| item.name.downcase }
                     .map { |group, count| slot_for(group, count) }
  end

  def any? = slots.any?

  # How many different things the recipe can make.
  def combinations = slots.map { _1.choices.size }.reduce(1, :*)

  # Whether any choice has a cost, which is worth a column.
  def costed? = slots.any? { |slot| slot.choices.any?(&:total) }

  private

  def slot_for(group, count)
    choices = group.members.includes(:game_keys).map { Choice.new(_1, @cost.cost_of_item(_1), count) }
    Slot.new(group, count, choices)
  end

end
