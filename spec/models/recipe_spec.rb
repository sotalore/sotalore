require "rails_helper"

RSpec.describe Recipe do

  it 'creates' do
    Recipe.create(name: 'Thing', craft_skill: 'carpentry')
  end

  let(:fuel1) { create :item, name: 'Fuel 1', use: 'fuel', price: 10 }
  let(:fuel2) { create :item, name: 'Fuel 2', use: 'fuel', price: 20 }
  let(:tool1) { create :item, name: 'Tool 1', use: 'tool' }
  let(:tool2) { create :item, name: 'Tool 2', use: 'tool' }

  describe '#fuel_cost' do
    subject { create :recipe, with_results: { tool1 => 1 },
                     with_ingredients: { fuel1 => 2, fuel2 => 3 } }

    it 'calculates the fuel_cost' do
      expect(subject.fuel_cost).to eq 80
    end
  end


  describe 'random' do
    context 'With no recipes' do
      it 'returns an empty array' do
        expect(Recipe.random).to eq []
      end
    end

    context 'With a recipe to find' do
      let!(:recipe) { create :recipe }
      it 'returns some of them' do
        expect(Recipe.random).to eq [recipe]
      end
    end
  end
end
