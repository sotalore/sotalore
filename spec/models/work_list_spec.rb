require "rails_helper"

RSpec.describe WorkList do

  let(:fuel1) { create :item, name: 'Fuel 1', use: 'fuel' }
  let(:fuel2) { create :item, name: 'Fuel 2', use: 'fuel' }
  let(:tool1) { create :item, name: 'Tool 1', use: 'tool' }
  let(:tool2) { create :item, name: 'Tool 2', use: 'tool' }
  let(:item1) { create :item, name: 'Component 1', use: 'component' }
  let(:mat1)  { create :item, name: 'Mat 1', gathering_skill: 'forestry' }
  let(:mat2)  { create :item, name: 'Mat 2', gathering_skill: 'mining' }

  subject { WorkList.new(recipe) }

  context 'Given a recursive recipe' do
    # I.e., Jar of Yeast Culture
    let(:item)        { create(:item) }
    let(:ingredients) { { fuel1 => 1, item => 1 } }
    let(:recipe)      { create :recipe, with_results: { item => 1 }, with_ingredients: ingredients }

    it 'has the fuels' do
      expect(subject.fuels).to eq([[fuel1, 1]])
    end

    it 'has the recursive requirements' do
      expect(subject.recursive).to eq([item])
    end

    it 'has the single recipe' do
      expect(subject.recipes).to eq([[recipe, 1]])
    end
  end

  context 'Given a recipe with gathered resources' do
    let(:ingredients) { { fuel1 => 1, tool1 => 1, mat1 => 2 } }
    let(:recipe) { create :recipe, with_ingredients: ingredients }

    it 'has the gathered_materials' do
      expect(subject.gathered).to eq([[mat1, 2]])
    end
  end

  context 'Given a recipe with bought components' do
    # Essentially, components that can't be made or gathered.

    let(:ingredients) { { fuel1 => 1, tool1 => 1, item1 => 2 } }
    let(:recipe) { create :recipe, with_ingredients: ingredients }

    it 'has the components' do
      expect(subject.components).to eq([[item1, 2]])
    end
  end

  context 'Given a simple recipe' do
    let(:ingredients) { { fuel1 => 1, tool1 => 1, fuel2 => 2 } }
    let(:recipe) { create :recipe, with_ingredients: ingredients }

    it 'contains the fuels' do
      expect(subject.fuels).to contain_exactly([ fuel2, 2 ], [fuel1, 1])
    end

    it 'contains the tool1' do
      expect(subject.tools).to eq([tool1])
    end
  end

  context 'Given a recipe with a sub recipe multiplied' do
    let!(:sub_ingredients) { { fuel1 => 1, tool1 => 1, tool2 =>1, fuel2 => 2, item1 => 2 } }
    let!(:sub_recipe)      { create :recipe, with_ingredients: sub_ingredients }
    before do
      # I want 3 of these, so I have to execute this twice
      sub_recipe.results.first.update(count: 2)
    end
    let!(:sub_item)        { sub_recipe.results.first.item }
    let!(:ingredients)     { { fuel1 => 1, tool1 => 1, fuel2 => 2, sub_item => 3, item1 => 4 } }
    let!(:recipe)          { create :recipe, with_ingredients: ingredients }

    it 'contains all fuels' do
      expect(subject.fuels).to contain_exactly([fuel1, 3], [fuel2, 6])
    end

    it 'contains just the tools' do
      expect(subject.tools).to contain_exactly(tool1, tool2)
    end

    it 'contains the components' do
      expect(subject.components).to eq([[ item1, 8 ]])
    end

    it 'contains the sub_recipe' do
      expect(subject.recipes).to eq([ [recipe, 1], [sub_recipe, 2] ])
    end
  end

end
