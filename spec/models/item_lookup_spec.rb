require 'rails_helper'

RSpec.describe ItemLookup do
  let!(:board) { create(:item, name: 'Oak Board') }
  let!(:old)   { create(:item, name: 'Old Oak Board') }

  it 'resolves names and aliases, case-insensitively' do
    ItemAlias.create!(item: board, name: 'Oaken Board')
    lookup = ItemLookup.new
    expect([ lookup.id_for('oak board'), lookup.id_for('Oaken Board'), lookup.id_for('Elm') ])
      .to eq [ board.id, board.id, nil ]
  end

  it 'resolves a line by its game key first, then by name' do
    old.game_keys.create!(key: item_key(1), name: 'Old Oak Board')
    lookup = ItemLookup.new
    line = ->(name, key) { GameRecipe::Line.new(name: name, count: 1, key: key) }
    expect(lookup.id_for(line.('Oak Board', item_key(1)))).to eq old.id
    expect(lookup.id_for(line.('Oak Board', item_key(2)))).to eq board.id
    expect(lookup.id_for(line.('Oak Board', nil))).to eq board.id
    expect(lookup.known?(line.('Renamed Board', item_key(1)))).to be true
  end
end
