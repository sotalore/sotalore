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

  describe 'templates and variants' do
    let(:blade)  { create :item, name: 'Dagger Blade', abstract: true }
    let(:iron)   { create :item, name: 'Iron Dagger Blade' }
    let(:bronze) { create :item, name: 'Bronze Dagger Blade' }
    let(:ingot)  { create :item, name: 'Iron Ingot' }
    let(:bingot) { create :item, name: 'Bronze Ingot' }
    let(:mingot) { create :item, name: 'Metal Ingot', abstract: true }

    let!(:template) { create :recipe, name: 'Dagger Blade', with_ingredients: { mingot => 1 }, with_results: { blade => 1 } }
    let!(:iron_recipe) { create :recipe, name: 'Iron Dagger Blade', with_ingredients: { ingot => 1 }, with_results: { iron => 1 } }
    let!(:bronze_recipe) { create :recipe, name: 'Bronze Dagger Blade', with_ingredients: { bingot => 1 }, with_results: { bronze => 1 } }

    before do
      ItemMembership.create!(group: blade, member: iron)
      ItemMembership.create!(group: blade, member: bronze)
    end

    it 'knows template recipes' do
      expect(template).to be_template
      expect(iron_recipe).not_to be_template
      expect(Recipe.templates).to eq [ template ]
      expect(Recipe.concrete).to contain_exactly(iron_recipe, bronze_recipe)
    end

    it 'lists the concrete recipes for a template' do
      expect(template.variants).to contain_exactly(iron_recipe, bronze_recipe)
      expect(iron_recipe.variants).to be_empty
    end

    it 'links a concrete recipe to its groups and templates' do
      expect(iron_recipe.result_groups).to eq [ blade ]
      expect(iron_recipe.templates).to eq [ template ]
    end
  end
end
