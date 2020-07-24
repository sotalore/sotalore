require 'rails_helper'

RSpec.describe CraftSkill do
  it 'has the right count' do
    expect(CraftSkill::ALL.size).to eq 16
  end

  it 'loads from a String' do
    expect(CraftSkill.load('field_dressing')).to eq CraftSkill::ALL.first
  end

  it 'dumps to a string' do
    expect(CraftSkill.dump(CraftSkill::ALL.first)).to eq 'field_dressing'
  end

  it 'has a primary tool for everything' do
    expect(CraftSkill::ALL.map(&:primary_tool).all?).to eq true
  end

end
