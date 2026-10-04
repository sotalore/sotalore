require 'rails_helper'

RSpec.describe ItemMembership do
  let(:ingot)       { create(:item, name: 'Metal Ingot', kind: :group) }
  let(:copper_iron) { create(:item, name: 'Copper or Iron Ingot', kind: :group) }
  let(:iron)        { create(:item, name: 'Iron Ingot') }
  let(:bronze)      { create(:item, name: 'Bronze Ingot') }

  it 'lets one item belong to many groups' do
    ItemMembership.create!(group: ingot, member: iron)
    ItemMembership.create!(group: copper_iron, member: iron)
    ItemMembership.create!(group: ingot, member: bronze)

    expect(iron.groups).to eq [ copper_iron, ingot ]
    expect(ingot.members).to eq [ bronze, iron ]
  end

  it 'lets a category list examples' do
    armor = create(:item, name: 'Crafted Chest Armor', kind: :category)
    plate = create(:item, name: 'Plate Chest')
    ItemMembership.create!(group: armor, member: plate)
    expect(armor.members).to eq [ plate ]
    expect(plate.groups).to eq [ armor ]
  end

  it 'requires the group to be a group or category and the member concrete' do
    dagger = create(:item, name: 'Dagger', kind: :archetype)
    armor  = create(:item, name: 'Crafted Chest Armor', kind: :category)
    expect(ItemMembership.new(group: iron, member: bronze)).not_to be_valid
    expect(ItemMembership.new(group: dagger, member: bronze)).not_to be_valid
    expect(ItemMembership.new(group: ingot, member: copper_iron)).not_to be_valid
    expect(ItemMembership.new(group: ingot, member: dagger)).not_to be_valid
    expect(ItemMembership.new(group: armor, member: copper_iron)).not_to be_valid
  end

  it 'rejects duplicates' do
    ItemMembership.create!(group: ingot, member: iron)
    expect(ItemMembership.new(group: ingot, member: iron)).not_to be_valid
  end

  it 'refuses kind changes that would break memberships' do
    ItemMembership.create!(group: ingot, member: iron)
    expect(iron.update(kind: :group)).to be false
    expect(iron.errors[:kind].join).to include 'member of a group'
    expect(ingot.update(kind: :archetype)).to be false
    expect(ingot.errors[:kind].join).to include 'has members'
    expect(ingot.update(kind: :category)).to be true
    expect(ingot.update(kind: :group, name: 'Metal Ingots')).to be true
  end

  it 'goes away with either item' do
    ItemMembership.create!(group: ingot, member: iron)
    expect { iron.destroy }.to change(ItemMembership, :count).by(-1)
  end
end
