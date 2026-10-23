# frozen_string_literal: true

# What one run of a recipe costs a user, from what each ingredient costs
# them. An item costs, whichever comes first:
#
#   1. the user's market price for it (what they'd pay, or give up by using
#      their own),
#   2. its merchant price (an NPC sells it),
#   3. what making it costs, by its cheapest active recipe, costed the same
#      way.
#
# A group costs what its cheapest member does: any member will do. Tools are
# left out: they wear slowly, so they're an operating cost, not part of each
# item's. Modifications (which act on something brought along), templates
# (whose cost depends on the variant) and recipes taking a category can't
# be costed at all; see #costable?.
class RecipeCost

  # +source+ is :market, :merchant or :made, or nil when there's no cost.
  # +via+ is the member a group's cost comes from, or the recipe a made
  # item's comes from.
  Cost = Data.define(:unit, :source, :via)

  Line = Data.define(:item, :count, :cost) do
    def known? = !cost.nil?
    def total = cost && cost.unit * count
  end

  attr_reader :recipe

  def initialize(recipe, user)
    @recipe = recipe
    @market = user.null? ? {} : user.market_prices.pluck(:item_id, :price).to_h
    @costs = {}
  end

  # Whether the user has any market prices: someone pricing things, who'd
  # want to know what's missing.
  def pricing? = @market.any?

  def costable?
    return @costable if defined?(@costable)
    @costable = !recipe.modification? && recipe.kind != 'template' &&
                consumed.none? { _1.item.category? || _1.item.archetype? }
  end

  def lines
    @lines ||= consumed.map { Line.new(_1.item, _1.count, cost_of(_1.item, Set[recipe.id])) }
  end

  def complete? = costable? && lines.all?(&:known?)
  def missing = lines.reject(&:known?).map(&:item)
  def total = complete? ? lines.sum(&:total) : nil

  # The one thing it makes, and how many: nil for recipes making several.
  def result = recipe.results.one? ? recipe.results.first : nil

  def per_item
    total && result && total / result.count
  end

  # The user's market price for what it makes.
  def result_market_price
    result && @market[result.item_id]
  end

  private

  def consumed
    recipe.ingredients.reject { _1.item.use_is_tool? }
  end

  # +seen+ holds the recipes being costed further up, so a recipe that
  # (eventually) takes what it makes isn't followed round in circles.
  def cost_of(item, seen)
    return @costs[item.id] if @costs.key?(item.id)
    cost =
      if item.group? then cheapest_member(item, seen)
      elsif !item.concrete? then nil
      elsif (price = @market[item.id]) then Cost.new(price, :market, nil)
      elsif item.merchant_price then Cost.new(item.merchant_price.to_d, :merchant, nil)
      else cost_to_make(item, seen)
      end
    @costs[item.id] = cost
  end

  def cheapest_member(group, seen)
    group.members.filter_map { |member| (cost = cost_of(member, seen)) && [ member, cost ] }
         .min_by { |_, cost| cost.unit }
         &.then { |member, cost| Cost.new(cost.unit, cost.source, member) }
  end

  def cost_to_make(item, seen)
    item.results.includes(recipe: [ { ingredients: :item }, { results: :item } ]).filter_map do |result|
      maker = result.recipe
      next if maker.retired? || seen.include?(maker.id) || maker.modification?
      run = run_cost(maker, seen + [ maker.id ]) or next
      Cost.new(run / result.count, :made, maker)
    end.min_by(&:unit)
  end

  def run_cost(maker, seen)
    maker.ingredients.reject { _1.item.use_is_tool? }.sum do |ingredient|
      cost = cost_of(ingredient.item, seen) or return nil
      cost.unit * ingredient.count
    end
  end
end
