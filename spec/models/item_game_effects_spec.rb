require 'rails_helper'

RSpec.describe Item, 'game effects' do
  let(:hilt) { create(:item, name: 'Elven Hilt') }

  def capture(item, key, details)
    item.game_keys.create!(key: item_key(key), name: item.name, catalog: { 'value' => 5, 'details' => details })
  end

  it "reads the tooltip's effects and crafting bonus from the game keys, without repeats" do
    capture(hilt, 'hilt', { 'effects' => [ '+1 Weapon Damage' ], 'craftingBonus' => [ '+3% Melee and Ranged Critical Chance', '+3 Dexterity' ] })
    capture(hilt, 'hilt2', { 'craftingBonus' => [ '+3 Dexterity', '' ] })
    expect(hilt.game_effects).to eq [ '+1 Weapon Damage' ]
    expect(hilt.crafting_bonus).to contain_exactly('+3% Melee and Ranged Critical Chance', '+3 Dexterity')
    expect(hilt).to be_crafting_bonus_known
  end

  it 'knows the difference between no bonus and no capture yet' do
    board = create(:item, name: 'Pine Board')
    capture(board, 'board', { 'craftingBonus' => [] })
    old = create(:item, name: 'Copper Hilt')
    capture(old, 'old', { 'tool' => false })
    expect([ board.crafting_bonus, board.crafting_bonus_known? ]).to eq [ [], true ]
    expect([ old.crafting_bonus, old.crafting_bonus_known? ]).to eq [ [], false ]
    expect(create(:item, name: 'Never Seen').crafting_bonus_known?).to be false
  end
end
