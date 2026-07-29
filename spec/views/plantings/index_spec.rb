require 'rails_helper'

RSpec.describe Views::Plantings::Index, type: :model do
  subject(:view) { described_class.new(plantings: Planting.none) }

  describe '#seeds_grouped_by_speed' do
    let!(:seed1) { create :seed, use: :seed, price: 6 }
    let!(:seed2) { create :seed, use: :seed, price: 8 }
    let!(:seed3) { create :seed, use: :seed, price: 16 }
    let!(:seed4) { create :seed, use: :seed, price: 30 }

    it 'works' do
      expect(view.send(:seeds_grouped_by_speed))
        .to eq([
                 [ "Quick (24 hours)", [ seed1, seed2 ] ],
                 [ "Medium (48 hours)", [ seed3 ] ],
                 [ "Slow (72 hours)", [ seed4 ] ],
               ])
    end

    it 'returns options too' do
      expect(view.send(:seeds_grouped_by_speed_options))
        .to eq([
                 [ "Quick (24 hours)",
                  [ [ seed1.name, seed1.id ], [ seed2.name, seed2.id ] ] ],
                 [ "Medium (48 hours)", [ [ seed3.name, seed3.id ] ] ],
                 [ "Slow (72 hours)", [ [ seed4.name, seed4.id ] ] ],
               ])
    end
  end
end
