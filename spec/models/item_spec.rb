require 'rails_helper'

RSpec.describe Item do

  describe 'destruction' do
    let!(:item) { create :item }

    context 'Given a identically named recipe' do
      let!(:recipe) { create :recipe, name: item.name.upcase, with_results: { item => 1 } }
      it 'cleans up the recipe' do
        expect { item.destroy }
          .to change { Item.count }.by(-1)
          .and change { Recipe.count }.by(-1)
      end
    end

    context 'Given the item is an ingredient' do
      let!(:recipe) { create :recipe, name: item.name.upcase, with_ingredients: { item => 1 } }
      it 'does not allow destruction' do
        expect { item.destroy }
          .to change { Item.count }.by(0)
          .and change { Recipe.count }.by(0)
      end
    end
  end

end
