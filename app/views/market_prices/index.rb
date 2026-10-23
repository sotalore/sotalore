# frozen_string_literal: true

# A user's own market prices, beside each item's value (what a merchant
# pays) and merchant price (what a merchant sells it for).
class Views::MarketPrices::Index < Views::Base

  def initialize(market_prices:)
    @market_prices = market_prices
  end

  def view_template
    page_title("Your Market Prices")
    tile do
      tile_heading("Your Market Prices")
      tile_body do
        p(class: "text-sm mb-2") do
          plain "What you reckon players trade one of each item for. Only you see them. "
          plain "Set one from an item's page."
        end
        if @market_prices.empty?
          p { em { "None yet." } }
        else
          prices_table
        end
      end
    end
  end

  private

  def prices_table
    table(class: "w-full text-sm") do
      thead do
        tr(class: "border-b-2 border-grey-400 text-left") do
          th(class: "pr-4") { "Item" }
          th(class: "pr-4 text-right") { "Market price" }
          th(class: "pr-4 text-right") { "Value" }
          th(class: "text-right") { "Merchant price" }
        end
      end
      tbody do
        @market_prices.each do |market_price|
          item = market_price.item
          tr(class: "border-b border-grey-200 dark:border-grey-700") do
            td(class: "py-1 pr-4 font-semibold") { link_to(item.name, item) }
            td(class: "py-1 pr-4 text-right") { market_price.to_s }
            td(class: "py-1 pr-4 text-right") { item.value&.to_s || "–" }
            td(class: "py-1 text-right") { item.merchant_price&.to_s || "–" }
          end
        end
      end
    end
  end
end
