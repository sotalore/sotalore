require 'rails_helper'

RSpec.describe Collection do
  let(:armor)    { Collection.create!(name: 'Armor') }
  let(:light)    { Collection.create!(name: 'Light Armor') }
  let(:leather)  { Collection.create!(name: 'Leather Armor') }
  let(:fortified) { Collection.create!(name: 'Fortified Leather Armor') }

  before do
    CollectionLink.create!(parent: armor, child: light)
    CollectionLink.create!(parent: light, child: fortified)
    CollectionLink.create!(parent: leather, child: fortified)
  end

  it 'knows what is inside it and what it is inside, however deep' do
    expect(armor.descendant_ids).to contain_exactly(light.id, fortified.id)
    expect(fortified.ancestor_ids).to contain_exactly(light.id, leather.id, armor.id)
    expect(Collection.top_level).to contain_exactly(armor, leather)
    expect(light.possible_parents).to eq [ armor, leather ]
  end

  it 'holds the items of everything inside it, saying where each is listed' do
    boots = create(:item, name: 'Fortified Leather Boots', kind: :archetype)
    helm  = create(:item, name: 'Leather Helm', kind: :archetype)
    fortified.collection_items.create!(item: boots)
    light.collection_items.create!(item: boots)
    leather.collection_items.create!(item: helm)

    expect(armor.all_items).to eq(boots => [ fortified, light ])
    expect(leather.all_items.keys).to eq [ boots, helm ]
  end

  it 'never sits inside itself' do
    loop = CollectionLink.new(parent: fortified, child: armor)
    expect(loop).not_to be_valid
    expect(loop.errors[:base].first).to include "Armor can't be inside Fortified Leather Armor"
    expect(CollectionLink.new(parent: armor, child: armor)).not_to be_valid
  end

  it 'lists concrete items and archetypes, not groups or categories' do
    group = create(:item, name: 'Yard of Leather', kind: :group)
    entry = light.collection_items.build(item: group)
    expect(entry).not_to be_valid
    expect(entry.errors[:item]).to eq [ 'must be a concrete item or an archetype, not a group' ]
    expect(light.collection_items.build(item: create(:item, name: 'Wax'))).to be_valid
  end

  it 'has a name unique without regard to case' do
    expect(Collection.new(name: 'light armor')).not_to be_valid
  end
end
