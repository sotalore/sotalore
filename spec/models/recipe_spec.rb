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
    let(:blade)  { create :item, name: 'Dagger Blade', kind: :group }
    let(:iron)   { create :item, name: 'Iron Dagger Blade' }
    let(:bronze) { create :item, name: 'Bronze Dagger Blade' }
    let(:ingot)  { create :item, name: 'Iron Ingot' }
    let(:bingot) { create :item, name: 'Bronze Ingot' }
    let(:mingot) { create :item, name: 'Metal Ingot', kind: :group }

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

    describe 'kinds' do
      let(:dagger)    { create :item, name: 'Dagger', kind: :archetype }
      let(:equipable) { create :item, name: 'Crafted Carpentry Equipable', kind: :category }
      let(:yeast)     { create :item, name: 'Yeast' }
      let!(:archetype) { create :recipe, name: 'Dagger', with_ingredients: { blade => 1 }, with_results: { dagger => 1 } }
      let!(:upgrade) do
        create :recipe, name: 'Masterwork Carpentry Upgrade', with_ingredients: { equipable => 1, ingot => 1 },
                        with_results: { equipable => 1 }
      end
      let!(:clone) { create :recipe, name: 'Clone Yeast', with_ingredients: { yeast => 1 }, with_results: { yeast => 3 } }

      it 'tells them apart' do
        expect([ upgrade, template, archetype, iron_recipe, clone ].map(&:kind))
          .to eq %w[ modification template archetype concrete concrete ]
        expect(upgrade.modified_items).to eq [ equipable ]
        expect(clone.modified_items).to be_empty
      end

      it 'has a scope for each' do
        expect(Recipe.modifications).to eq [ upgrade ]
        expect(Recipe.templates).to eq [ template ]
        expect(Recipe.archetypes).to eq [ archetype ]
        expect(Recipe.concrete).to contain_exactly(iron_recipe, bronze_recipe, clone)
      end

      it 'counts a modification of a concrete item as a modification' do
        chair = create :item, name: 'Chair'
        polish = create :recipe, name: 'Polish Chair', with_ingredients: { chair => 1, ingot => 1 },
                                 with_results: { chair => 1 }
        expect(polish).to be_modification
        expect(Recipe.modifications).to include polish
      end
    end
  end
end
