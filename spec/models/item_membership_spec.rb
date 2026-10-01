require 'rails_helper'

RSpec.describe ItemMembership do
  let(:ingot)       { create(:item, name: 'Metal Ingot', abstract: true) }
  let(:copper_iron) { create(:item, name: 'Copper or Iron Ingot', abstract: true) }
  let(:iron)        { create(:item, name: 'Iron Ingot') }
  let(:bronze)      { create(:item, name: 'Bronze Ingot') }

  it 'lets one item belong to many groups' do
    ItemMembership.create!(group: ingot, member: iron)
    ItemMembership.create!(group: copper_iron, member: iron)
    ItemMembership.create!(group: ingot, member: bronze)

    expect(iron.groups).to eq [ copper_iron, ingot ]
    expect(ingot.members).to eq [ bronze, iron ]
  end

  it 'requires the group to be abstract and the member concrete' do
    expect(ItemMembership.new(group: iron, member: bronze)).not_to be_valid
    expect(ItemMembership.new(group: ingot, member: copper_iron)).not_to be_valid
  end

  it 'rejects duplicates' do
    ItemMembership.create!(group: ingot, member: iron)
    expect(ItemMembership.new(group: ingot, member: iron)).not_to be_valid
  end

  it 'keeps groups flat when abstract is toggled' do
    ItemMembership.create!(group: ingot, member: iron)
    expect(iron.update(abstract: true)).to be false
    expect(ingot.update(abstract: false)).to be false
  end

  it 'goes away with either item' do
    ItemMembership.create!(group: ingot, member: iron)
    expect { iron.destroy }.to change(ItemMembership, :count).by(-1)
  end
end
