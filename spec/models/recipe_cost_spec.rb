require 'rails_helper'

RSpec.describe RecipeCost do
  let(:user) { create :user }
  let(:coal)   { create :item, name: 'Chunk of Coal', use: 'fuel', merchant_price: 6 }
  let(:garlic) { create :item, name: 'Garlic', merchant_price: 4 }
  let(:milk)   { create :item, name: 'Bottle of Milk', merchant_price: 10 }
  let(:butter) { create :item, name: 'Butter' }
  let(:pestle) { create :item, name: 'Mortar and Pestle', use: 'tool' }
  let(:bread)  { create :item, name: 'Garlic Bread' }

  let!(:churn) { create :recipe, name: 'Butter', with_ingredients: { milk => 1 }, with_results: { butter => 3 } }
  let(:recipe) do
    create :recipe, name: 'Garlic Bread', with_ingredients: { coal => 1, garlic => 2, butter => 1, pestle => 1 },
                    with_results: { bread => 4 }
  end

  def cost(recipe = self.recipe) = RecipeCost.new(Recipe.find(recipe.id), user)

  it 'costs each ingredient by market price, else merchant price, else making it, leaving tools out' do
    user.market_prices.create!(item: garlic, price: 1.2)
    c = cost
    expect(c).to be_complete
    expect(c.lines.map { [ _1.item.name, _1.cost.source, _1.total.round(2) ] }).to eq [
      [ 'Chunk of Coal', :merchant, 6 ], [ 'Garlic', :market, 2.4 ], [ 'Butter', :made, BigDecimal('3.33') ]
    ]
    expect(c.lines.last.cost.via).to eq churn
    expect(c.total.round(2)).to eq BigDecimal('11.73')
    expect(c.per_item.round(2)).to eq BigDecimal('2.93')
  end

  it 'costs a group by its cheapest member' do
    cheese = create :item, name: 'Cheese', kind: :group
    cheap, dear = create(:item, name: 'Wedge of Cheese', merchant_price: 18), create(:item, name: 'Goat Cheese', merchant_price: 30)
    unpriced = create(:item, name: 'Blue Cheese')
    [ cheap, dear, unpriced ].each { ItemMembership.create!(group: cheese, member: _1) }
    toast = create :recipe, with_ingredients: { cheese => 2 }

    line = cost(toast).lines.sole
    expect(line.cost).to have_attributes(unit: 18, source: :merchant, via: cheap)
    expect(line.total).to eq 36
  end

  it "says what's missing, and whether the user prices things" do
    milk.update!(merchant_price: nil)
    expect(cost).not_to be_complete
    expect(cost.missing).to eq [ butter ]
    expect(cost.total).to be_nil
    expect(cost).not_to be_pricing
    user.market_prices.create!(item: garlic, price: 1)
    expect(cost).to be_pricing
  end

  it "doesn't follow a recipe round in circles" do
    create :recipe, with_ingredients: { butter => 1 }, with_results: { milk => 1 }
    milk.update!(merchant_price: nil)
    expect(cost.missing).to eq [ butter ]
  end

  it "can't cost modifications or recipes taking a category" do
    weapon = create :item, name: 'Crafted Weapon', kind: :category
    expect(cost(create(:recipe, with_ingredients: { weapon => 1, coal => 1 }))).not_to be_costable
    expect(cost(create(:recipe, with_ingredients: { bread => 1, garlic => 1 }, with_results: { bread => 1 }))).not_to be_costable
  end

  it "gives the user's market price for what it makes" do
    user.market_prices.create!(item: bread, price: 5)
    expect(cost.result_market_price).to eq 5
  end
end
