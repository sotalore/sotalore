# frozen_string_literal: true

# A user's own market prices: what they reckon players trade items for.
# Set and cleared from an item's page; listed together on the index.
class MarketPricesController < ApplicationController

  before_action     :authenticate_user!
  skip_after_action :verify_authorized

  def index
    market_prices = Current.user.market_prices.joins(:item).includes(:item).order('items.name')
    render Views::MarketPrices::Index.new(market_prices: market_prices)
  end

  def update
    item = Item.find(params[:item_id])
    market_price = Current.user.market_prices.find_or_initialize_by(item: item)
    if market_price.update(params.require(:market_price).permit(:price))
      redirect_back_or_to item, notice: "Your market price for #{item.name} is #{market_price} gold."
    else
      redirect_back_or_to item, alert: "Couldn't set your market price: #{market_price.errors.full_messages.to_sentence}."
    end
  end

  def destroy
    item = Item.find(params[:item_id])
    Current.user.market_prices.where(item: item).delete_all
    redirect_back_or_to item, notice: "Your market price for #{item.name} is cleared."
  end
end
