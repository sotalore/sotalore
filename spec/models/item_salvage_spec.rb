require 'rails_helper'

RSpec.describe ItemSalvage, type: :model do

  let!(:item1) { create :item }
  let!(:item2) { create :item }

  describe 'The basics' do

    it 'does not salvage' do
      expect(item1.salvage_as_result_count).to eq 0
      expect(item1.salvage_as_source_count).to eq 0
    end

    it 'salvages to and from' do
      item1.salvages_to << item2

      item1.reload
      item2.reload

      expect(item1.salvage_as_result_count).to eq 0
      expect(item1.salvages_from).to be_empty
      expect(item1.salvage_as_source_count).to eq 1
      expect(item1.salvages_to).to eq [item2]

      expect(item2.salvage_as_result_count).to eq 1
      expect(item2.salvages_from).to eq [item1]
      expect(item2.salvage_as_source_count).to eq 0
      expect(item2.salvages_to).to be_empty
    end

    it 'cannot salvage into self' do

      item_salvage = item1.item_salvages_as_source.build(salvage_to: item1)
      expect(item_salvage).to_not be_valid
    end
  end
end
