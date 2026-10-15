require 'rails_helper'

RSpec.describe GameWeights do
  let(:user) { create(:user, :root) }
  let!(:wax)   { create(:item, name: 'Wax', weight: 0.1) }
  let!(:board) { create(:item, name: 'Oak Board') }
  let!(:chair) { create(:item, name: 'Chair', weight: 2) }
  let!(:stool) { create(:item, name: 'Stool') }

  let(:import) do
    recipe = game_recipe_hash(name: 'Chair', ingredients: { 'Wax' => 3, 'Boards' => 2, 'Stool' => 1 },
                              keys: { 'Wax' => item_key('wax'), 'Boards' => 'group:7', 'Stool' => item_key('stool1'),
                                      'Chair' => item_key('chair') },
                              stats: { 'Chair' => [ { 'key' => 'weight', 'value' => 2 } ] })
    recipe['ingredients'][0]['stats'] = [ { 'key' => 'weight', 'value' => 0.05 } ]
    recipe['ingredients'][1]['choices'] = [ { 'key' => item_key('board'), 'stats' => [ { 'key' => 'weight', 'value' => 1.5 } ] } ]
    recipe['ingredients'][2]['stats'] = [ { 'key' => 'weight', 'value' => 4 } ]
    other = game_recipe_hash(name: 'Bench', results: { 'Stool' => 1 }, keys: { 'Stool' => item_key('stool2') },
                             stats: { 'Stool' => [ { 'key' => 'weight', 'value' => 5 } ] })
    RecipeImport.create_from_json!(game_export_json(recipe, other), user: user)
  end

  before do
    { wax => 'wax', board => 'board', chair => 'chair', stool => 'stool1' }.each do |item, seed|
      item.game_keys.create!(key: item_key(seed), name: item.name)
    end
    stool.game_keys.create!(key: item_key('stool2'), name: 'Stool')
  end

  subject(:weights) { GameWeights.new(import, user) }

  it 'reads weights from results, ingredients and group choices' do
    expect(import.entries.find_by!(name: 'Chair').game_recipe.item_weights)
      .to eq(item_key('chair') => 2, item_key('wax') => 0.05, item_key('board') => 1.5, item_key('stool1') => 4)
  end

  it 'compares them with the site' do
    expect(weights.rows.to_h { [ _1.item, [ _1.status, _1.weights ] ] }).to eq(
      board => [ 'missing', [ BigDecimal('1.5') ] ],
      wax => [ 'different', [ BigDecimal('0.05') ] ],
      stool => [ 'conflict', [ BigDecimal('4'), BigDecimal('5') ] ],
      chair => [ 'same', [ BigDecimal('2') ] ])
  end

  it 'fills missing and updates different weights, with revisions' do
    expect(weights.set!('missing')).to eq 1
    expect(board.reload.weight).to eq BigDecimal('1.5')
    expect(wax.reload.weight).to eq BigDecimal('0.1')
    expect(board.comments.count).to eq 1

    expect(GameWeights.new(import, user).set!('different')).to eq 1
    expect(wax.reload.weight).to eq BigDecimal('0.05')
    expect { weights.set!('conflict') }.to raise_error(ArgumentError)
  end

  it 'sets at most a limited number at a time' do
    wax.update!(weight: nil)
    expect(weights.set!('missing', limit: 1)).to eq 1
    expect(GameWeights.new(import, user).counts['missing']).to eq 1
  end
end
