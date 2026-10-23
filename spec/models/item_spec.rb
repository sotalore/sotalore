require 'rails_helper'

RSpec.describe Item do

  describe 'USE_TAG uniqueness' do
    it 'has no duplicates' do
      expect(Item::ITEM_USES.values.length)
        .to eq(Item::ITEM_USES.values.uniq.length)
    end
  end

  describe 'kinds' do
    it 'treats everything but concrete as abstract' do
      concrete = create(:item)
      group = create(:item, kind: :group)
      archetype = create(:item, kind: :archetype, name: 'Dagger')
      expect(Item.abstract).to contain_exactly(group, archetype)
      expect([ concrete, group, archetype ].map(&:abstract?)).to eq [ false, true, true ]
      expect(archetype.kind_label).to eq 'an archetype'
    end

    it 'refuses a merchant price on abstract items' do
      expect(build(:item, kind: :category, merchant_price: 10)).not_to be_valid
    end

    it 'refuses a merchant price at or below the value, unless the item has no value' do
      expect(build(:item, value: 10, merchant_price: 10)).not_to be_valid
      expect(build(:item, value: 10, merchant_price: 20)).to be_valid
      expect(build(:item, value: 0, merchant_price: 4)).to be_valid
    end

    it 'keeps a merchant price when a new value catches up with it' do
      item = create(:item, value: 1, merchant_price: 4)
      expect(item.update(value: 4)).to be true
    end
  end

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
