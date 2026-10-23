require 'rails_helper'

RSpec.describe "Market prices", type: :request do
  let!(:current_user) { create :user }
  let!(:garlic) { create :item, name: 'Garlic', value: 3, merchant_price: 6 }

  context 'signed in' do
    before { sign_in current_user }

    it "shows the user's own market price on an item's page" do
      current_user.market_prices.create!(item: garlic, price: 1.2)
      create(:user).market_prices.create!(item: garlic, price: 5)
      get item_path(garlic)
      expect(response.body).to include('Your Market Price', 'value="1.2"')
    end

    it 'sets, changes and clears a market price' do
      patch item_market_price_path(garlic), params: { market_price: { price: '1.2' } }
      expect(response).to redirect_to(item_path(garlic))
      expect(flash[:notice]).to eq 'Your market price for Garlic is 1.2 gold.'
      patch item_market_price_path(garlic), params: { market_price: { price: '2' } }
      expect(MarketPrice.where(user: current_user).sole).to have_attributes(item: garlic, price: BigDecimal('2'))

      delete item_market_price_path(garlic)
      expect(MarketPrice.where(user: current_user)).to be_empty
    end

    it 'refuses a price that is not more than nothing' do
      patch item_market_price_path(garlic), params: { market_price: { price: '0' } }
      expect(flash[:alert]).to match(/must be greater than 0/)
      expect(MarketPrice.where(user: current_user)).to be_empty
    end

    it 'refuses a market price for an abstract item' do
      metal = create(:item, name: 'Metal', kind: :category)
      patch item_market_price_path(metal), params: { market_price: { price: '5' } }
      expect(flash[:alert]).to match(/concrete item/)
    end

    it "lists only the user's own market prices" do
      onion = create(:item, name: 'Onion')
      current_user.market_prices.create!(item: garlic, price: 1.2)
      create(:user).market_prices.create!(item: onion, price: 5)
      get market_prices_path
      expect(response.body).to include('Garlic', '1.2')
      expect(response.body).not_to include('Onion')
    end
  end

  it 'needs a signed-in user' do
    get market_prices_path
    expect(response).to have_http_status(:redirect)
    patch item_market_price_path(garlic), params: { market_price: { price: '1' } }
    expect(response).to have_http_status(:redirect)
    expect(MarketPrice.count).to eq 0
  end

  it "doesn't offer a market price on an item's page when signed out" do
    get item_path(garlic)
    expect(response.body).not_to include('Your Market Price')
  end
end
