require 'rails_helper'

RSpec.describe ItemGameKey do
  let(:board) { create(:item, name: 'Oak Board') }
  let(:group) { create(:item, name: 'Wooden Board', kind: :group) }

  it 'takes item keys for concrete items and archetypes, group keys for groups and categories' do
    expect(ItemGameKey.new(item: board, key: item_key(1), name: 'Oak Board')).to be_valid
    expect(ItemGameKey.new(item: create(:item, name: 'Dagger', kind: :archetype), key: item_key(2), name: 'Dagger'))
      .to be_valid
    expect(ItemGameKey.new(item: group, key: 'group:-7', name: 'Wooden Board')).to be_valid
    expect(ItemGameKey.new(item: create(:item, name: 'X', kind: :category), key: 'group:8', name: 'X')).to be_valid

    wrong = ItemGameKey.new(item: board, key: 'group:7', name: 'Oak Board')
    expect(wrong).not_to be_valid
    expect(wrong.errors[:key].join).to include "a group key can't belong to a concrete"
    expect(ItemGameKey.new(item: group, key: item_key(3), name: 'Wooden Board')).not_to be_valid
  end

  it 'requires a well-formed, unique key' do
    expect(ItemGameKey.new(item: board, key: 'item:nothex', name: 'Oak Board')).not_to be_valid
    ItemGameKey.create!(item: board, key: item_key(1), name: 'Oak Board')
    expect(ItemGameKey.new(item: create(:item, name: 'Pine Board'), key: item_key(1), name: 'Pine Board'))
      .not_to be_valid
  end

  it 'lets an item have several keys, and goes away with it' do
    board.game_keys.create!(key: item_key(1), name: 'Oak Board')
    board.game_keys.create!(key: item_key(2), name: 'Oak Board')
    expect { board.destroy }.to change(ItemGameKey, :count).by(-2)
  end
end
