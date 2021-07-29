require 'rails_helper'

RSpec.describe ItemSalvage, type: :model do

  let!(:item1) { create :item }
  let!(:item2) { create :item }

  describe 'The basics' do

    it 'does not salvage' do
      expect(item1.salvage_from_count).to eq 0
      expect(item1.salvage_to_count).to eq 0
    end

    it 'salvages to and from' do
      item1.salvages_to << item2

      item1.reload
      item2.reload

      expect(item1.salvage_from_count).to eq 1
      expect(item1.salvage_to_count).to eq 0

      expect(item2.salvage_from_count).to eq 0
      expect(item2.salvage_to_count).to eq 1
    end

    it 'cannot salvage into self' do

      item_salvage = item1.item_salvages_as_source.build(salvage_to: item1)
      expect(item_salvage).to_not be_valid
    end
  end
end
