require 'rails_helper'

RSpec.describe GearType do
  it 'reads armor, shields and weapons from type lines' do
    expect(GearType.from_line('Leather Light Armor (Head)'))
      .to have_attributes(kind: 'armor', material: 'leather', weight: 'light', slot: 'head', use: 'armor')
    expect(GearType.from_line('Universal Heavy Armor (Head)')).to have_attributes(material: 'universal', weight: 'heavy')
    expect(GearType.from_line('Heavy Shield')).to have_attributes(kind: 'shield', weight: 'heavy', use: 'armor')
    expect(GearType.from_line('Two-handed Polearm - Polearm'))
      .to have_attributes(kind: 'weapon', weapon: 'Two-handed Polearm', damage: 'polearm', use: 'weapon')
    expect(GearType.from_line('Consumable - Non-Combat')).to be_nil
    expect(GearType.from_line('Quest Item')).to be_nil
  end

  it 'takes the first gear line, and matches filters' do
    type = GearType.parse([ 'Artifact', 'Longsword - Bladed', 'Copper Hilt' ])
    expect(type.line).to eq 'Longsword - Bladed'
    expect(type.matches?(kind: 'weapon', damage: 'bladed')).to be true
    expect(type.matches?(damage: 'bludgeon')).to be false
    expect(GearType.parse(nil)).to be_nil
  end

  it 'finds the gear among items, from their game keys' do
    helm = create(:item, name: 'Rusty Chainmail Helm')
    helm.game_keys.create!(key: item_key('helm'), name: helm.name, catalog: { 'details' => { 'types' => [ 'Chain Heavy Armor (Head)' ] } })
    wax = create(:item, name: 'Wax')
    wax.game_keys.create!(key: item_key('wax'), name: 'Wax', catalog: { 'details' => { 'types' => [ 'Refined Material' ] } })
    expect(GearType.items.transform_values(&:line)).to eq(helm => 'Chain Heavy Armor (Head)')
    expect(GearType.for_item(helm).slot).to eq 'head'
    expect(GearType.for_item(wax)).to be_nil
  end
end
