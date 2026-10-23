# frozen_string_literal: true

# On a concrete item's page, for a signed-in user: their own market price
# for it (what they reckon players trade one for), to set, change or clear.
#
#   render Components::Items::MarketPrice.new(market_price: Current.user.market_prices.find_or_initialize_by(item:))
class Components::Items::MarketPrice < Components::Base

  def initialize(market_price:)
    @market_price = market_price
    @item = market_price.item
  end

  def view_template
    tile_with_heading("Your Market Price") do
      p(class: "text-sm") { "What you reckon players trade one for. Only you see it." }
      render Grav::Views::Forms::FormBuilder.new(model: @market_price, url: item_market_price_path(@item),
                                                 method: "patch", style: :inline) do |f|
        f.number_field(:price, min: 0.01, step: 0.01, label: "Gold for one", class: "Field-input--numeric")
        f.form_actions { f.submit_button("Save") }
      end
      div(class: "flex flex-row flex-wrap items-baseline gap-x-4 text-sm") do
        if @market_price.persisted?
          button_to("Clear", item_market_price_path(@item), method: :delete, class: "Button Button--sm",
                    form: { class: "inline-block" })
        end
        a(href: market_prices_path, class: "Link") { "All your market prices" }
      end
    end
  end
end
