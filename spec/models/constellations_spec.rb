# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Constellations', type: :model do

  it 'has the correct orbital period' do
    expect(Constellations::ORBITAL_PERIOD).to eq(Clock::NB_YEAR)
  end

  it 'has the correct time_per_constellation' do
    expect(Constellations::TIME_PER_CONSTELLATION).to eq(14.days / 12)
  end

end
