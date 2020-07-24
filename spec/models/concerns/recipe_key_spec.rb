require "rails_helper"

RSpec.describe RecipeKey do

  class RecipeTest
    include RecipeKey

    attr_accessor :craft_skill, :ingredients
    def initialize(craft_skill, *ingredients)
      self.craft_skill = craft_skill
      self.ingredients = ingredients
    end
  end

  let(:ing1) { double(Ingredient, item_id: 1, count: 3) }
  let(:ing2) { double(Ingredient, item_id: 2, count: 6) }
  let(:craft_skill) { 'carpentry' }

  subject { RecipeTest.new(craft_skill, ing1, ing2) }

  context 'Given no craft skill' do
    let(:craft_skill) { nil }

    it 'returns nil' do
      expect(subject.generate_recipe_key).to be_nil
    end
  end

  context 'Given no ingredients' do
    subject { RecipeTest.new(craft_skill) }

    it 'returns nil' do
      expect(subject.generate_recipe_key).to be_nil
    end
  end

  context 'Given enough information' do
    subject { RecipeTest.new(craft_skill, ing1, ing2) }

    it 'generates a key' do
      expect(subject.generate_recipe_key).to eq 'carpentry-1:3-2:6'
    end

    context 'When the ingredients are in another order' do
      let(:one) { RecipeTest.new(craft_skill, ing1, ing2) }
      let(:two) { RecipeTest.new(craft_skill, ing2, ing1) }

      it 'generates identical keys key' do
        expect(one.generate_recipe_key)
          .to eq two.generate_recipe_key
      end
    end
  end

end
