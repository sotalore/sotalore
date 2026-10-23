require 'rails_helper'

RSpec.describe "A recipe's cost to make", type: :request do
  let(:user) { create :user }
  let(:garlic) { create :item, name: 'Garlic', merchant_price: 4 }
  let(:wax) { create :item, name: 'Wax' }
  let(:bread) { create :item, name: 'Garlic Bread', value: 3 }
  let(:recipe) { create :recipe, with_ingredients: { garlic => 2 }, with_results: { bread => 1 } }

  it 'shows when every ingredient has a cost, even signed out' do
    get recipe_path(recipe)
    expect(response.body).to include('Cost to Make', 'One run costs <strong>8 gold</strong>', 'A merchant pays 3 for one.')
  end

  it "compares the cost with the user's market price for what it makes" do
    sign_in user
    user.market_prices.create!(item: bread, price: 10)
    get recipe_path(recipe)
    expect(response.body).to include('You price Garlic Bread at 10: 2 more than making one costs.')
  end

  context 'when an ingredient has no cost' do
    let(:recipe) { create :recipe, with_ingredients: { garlic => 2, wax => 1 }, with_results: { bread => 1 } }

    it "isn't shown to someone who doesn't price things" do
      sign_in user
      get recipe_path(recipe)
      expect(response.body).not_to include('Cost to Make')
    end

    it "shows someone pricing things what's missing" do
      sign_in user
      user.market_prices.create!(item: bread, price: 10)
      get recipe_path(recipe)
      expect(response.body).to include('Cost to Make', 'No cost yet for', ">Wax</a>")
      expect(response.body).not_to include('One run costs')
    end
  end
end
