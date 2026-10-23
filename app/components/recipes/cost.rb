# frozen_string_literal: true

# Beside a recipe: what one run costs the user (see RecipeCost), each
# ingredient's part in it, and how that compares with what it makes. Shown
# when every ingredient has a cost, or, to someone pricing things, with what
# still needs one; otherwise not at all.
#
#   render Components::Recipes::Cost.new(cost: RecipeCost.new(recipe, Current.user))
class Components::Recipes::Cost < Components::Recipes::Base

  SOURCES = { market: "your price", merchant: "merchant", made: "made" }.freeze

  def initialize(cost:)
    @cost = cost
  end

  def render?
    @cost.complete? || (@cost.costable? && @cost.pricing?)
  end

  def view_template
    tile_with_heading("Cost to Make") do
      @cost.complete? ? summary : missing
      lines_list
      p(class: "mt-2 text-xs text-grey-600 dark:text-grey-300") do
        plain "Each ingredient costs your market price, else the merchant price, else what making it costs. "
        plain "Tools aren't counted: they wear slowly."
      end
    end
  end

  private

  def summary
    result = @cost.result
    p do
      plain "One run costs "
      strong { "#{gold(@cost.total)} gold" }
      plain ", #{gold(@cost.per_item)} for each of the #{result.count}" if result && result.count > 1
      plain "."
    end
    return unless result

    if (price = @cost.result_market_price)
      difference = price - @cost.per_item
      p do
        plain "You price #{result.item.name} at #{gold(price)}: "
        plain difference.negative? ? "#{gold(-difference)} less than making one costs." : "#{gold(difference)} more than making one costs."
      end
    end
    p { "A merchant pays #{result.item.value} for one." } if result.item.value&.positive?
  end

  def missing
    p do
      plain "No cost yet for "
      @cost.missing.each_with_index do |item, i|
        plain ", " if i.positive?
        link_to(item.name, item)
      end
      plain ". Give #{@cost.missing.one? ? 'it' : 'them'} a market price to cost this recipe."
    end
  end

  def lines_list
    ul(class: "mt-2 text-sm") do
      @cost.lines.select(&:known?).each do |line|
        li(class: "flex flex-row justify-between gap-x-2") do
          span do
            plain "#{line.count} #{line.item.name} "
            span(class: "text-xs text-grey-600 dark:text-grey-300") { source(line.cost) }
          end
          span(class: "whitespace-nowrap") { gold(line.total) }
        end
      end
    end
  end

  def source(cost)
    via = cost.via
    case via
    when Recipe then plain "(made by "; link_to(via.name, via); plain ")"
    when Item then plain "(#{via.name}, #{SOURCES[cost.source]})"
    else plain "(#{SOURCES[cost.source]})"
    end
  end

  def gold(amount)
    amount.round(2).to_s("F").delete_suffix(".0")
  end
end
