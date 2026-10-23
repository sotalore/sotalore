require 'rails_helper'

RSpec.describe MarketPrice do
  let(:user) { create :user }
  let(:garlic) { create :item, name: 'Garlic' }

  it 'keeps one price per user and item' do
    user.market_prices.create!(item: garlic, price: 1.2)
    expect(user.market_prices.build(item: garlic, price: 2)).not_to be_valid
    expect(create(:user).market_prices.build(item: garlic, price: 2)).to be_valid
  end

  it 'shows its price without trailing zeros' do
    expect([ 1.2, 6, 0.05 ].map { MarketPrice.new(price: _1).to_s }).to eq [ '1.2', '6', '0.05' ]
  end

  it 'goes with its user and its item' do
    user.market_prices.create!(item: garlic, price: 1.2)
    garlic.destroy!
    expect(MarketPrice.count).to eq 0
  end
end
