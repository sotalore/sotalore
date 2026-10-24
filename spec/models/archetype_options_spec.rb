require 'rails_helper'

RSpec.describe ArchetypeOptions do
  let(:user)  { create :user }
  let(:coal)  { create :item, name: 'Chunk of Coal', merchant_price: 6 }
  let(:blade) { create :item, name: 'Longsword Blade', kind: :group }
  let(:hilt)  { create :item, name: 'Metal Hilt', kind: :group }
  let(:sword) { create :item, name: 'Longsword', kind: :archetype }
  let(:recipe) do
    create :recipe, name: 'Longsword', with_ingredients: { coal => 3, hilt => 1, blade => 2 },
                    with_results: { sword => 1 }
  end

  let!(:copper_hilt) { member(hilt, 'Copper Hilt', merchant_price: 40, effects: '+1% Weapon Critical Chance') }
  let!(:iron_hilt)   { member(hilt, 'Iron Hilt', merchant_price: 30) }
  let!(:iron_blade)  { member(blade, 'Iron Longsword Blade') }
  let!(:bronze_blade) { member(blade, 'Bronze Longsword Blade') }

  def member(group, name, **attrs)
    create(:item, name: name, **attrs).tap { ItemMembership.create!(group: group, member: _1) }
  end

  def options(user = self.user)
    found = Recipe.find(recipe.id)
    ArchetypeOptions.new(found, RecipeCost.new(found, user))
  end

  it 'has a slot for each group the recipe takes, with its members as choices' do
    slots = options.slots
    expect(slots.map { [ _1.group, _1.count ] }).to eq [ [ blade, 2 ], [ hilt, 1 ] ]
    expect(slots.first.choices.map(&:item)).to eq [ bronze_blade, iron_blade ]
    expect(options.combinations).to eq 4
  end

  it 'costs each choice for the count the recipe takes, and finds the cheapest' do
    user.market_prices.create!(item: iron_blade, price: 12)
    blades, hilts = options.slots
    expect(blades.choices.map(&:total)).to eq [ nil, 24 ]
    expect(blades.cheapest.item).to eq iron_blade
    expect(hilts.cheapest.item).to eq iron_hilt
    expect(options).to be_costed
  end

  it 'has nothing to offer for a recipe without groups' do
    plain = create :recipe, with_ingredients: { coal => 1 }, with_results: { sword => 1 }
    expect(ArchetypeOptions.new(plain, RecipeCost.new(plain, user))).not_to be_any
  end
end
