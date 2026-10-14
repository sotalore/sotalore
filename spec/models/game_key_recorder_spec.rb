require 'rails_helper'

RSpec.describe GameKeyRecorder do
  let(:user) { create(:user, :root) }
  let!(:board) { create(:item, name: 'Wooden Board', kind: :group) }
  let!(:wax)   { create(:item, name: 'Wax') }
  let!(:chair) { create(:item, name: 'Chair') }

  def import_of(*recipes, groups: [])
    RecipeImport.create_from_json!(game_export_json(*recipes, groups: groups), filename: 'x.json', user: user)
  end

  def statuses(recorder)
    recorder.proposals.to_h { [ _1.key, _1.status ] }
  end

  let(:chair_stats) { [ { 'key' => 'durability', 'value' => 50 } ] }
  let(:chair_recipe) do
    game_recipe_hash(name: 'Chair', ingredients: { 'Wooden Board' => 2, 'Wax' => 1 },
                     keys: { 'Wooden Board' => 'group:7', 'Wax' => item_key('wax'), 'Chair' => item_key('chair') },
                     stats: { 'Chair' => chair_stats })
  end

  it 'records the keys whose names lead to one suitable item, with result stats' do
    recorder = GameKeyRecorder.new(import_of(chair_recipe))
    expect(statuses(recorder)).to eq('group:7' => 'record', item_key('wax') => 'record',
                                     item_key('chair') => 'record')
    expect(recorder.record!).to eq 3

    expect(board.game_keys.pluck(:key)).to eq [ 'group:7' ]
    expect(wax.game_keys.sole).to have_attributes(key: item_key('wax'), name: 'Wax', stats: nil)
    expect(chair.game_keys.sole.stats).to eq chair_stats
    expect(GameKeyRecorder.new(RecipeImport.last).counts).to include('known' => 3, 'record' => 0)
  end

  it 'refreshes the name and stats of known keys' do
    wax.game_keys.create!(key: item_key('wax'), name: 'Old Wax')
    ItemAlias.create!(item: wax, name: 'Beeswax')
    recipe = game_recipe_hash(name: 'Candle', ingredients: { 'Beeswax' => 1 }, results: { 'Chair' => 1 },
                              keys: { 'Beeswax' => item_key('wax') })
    GameKeyRecorder.new(import_of(recipe)).record!
    expect(wax.game_keys.sole.name).to eq 'Beeswax'
  end

  it 'leaves keys recorded for another item, unknown names, and wrong kinds alone' do
    wax.game_keys.create!(key: item_key('chair'), name: 'Wax')
    create(:item, name: 'Dragon Head')
    recipe = game_recipe_hash(name: 'Trophy', ingredients: { 'Dragon Head' => 1, 'Glue' => 1 },
                              results: { 'Chair' => 1 },
                              keys: { 'Dragon Head' => 'group:9', 'Glue' => item_key('glue'),
                                      'Chair' => item_key('chair') })
    recorder = GameKeyRecorder.new(import_of(recipe))
    expect(statuses(recorder)).to eq('group:9' => 'unsuited', item_key('glue') => 'unknown',
                                     item_key('chair') => 'elsewhere')
    expect(recorder.proposals.find { _1.key == 'group:9' }.note)
      .to eq 'a group slot, but the site has Dragon Head as a concrete'
    expect(recorder.record!).to eq 0
  end

  it 'leaves a name the export uses for several keys alone, unless they are the same group' do
    gem = create(:item, name: 'Gem Fragment', kind: :group)
    fragments = { item_key('ruby') => 'Ruby Fragment', item_key('onyx') => 'Onyx Fragment' }
    import = import_of(
      game_recipe_hash(name: 'Chair', ingredients: { 'Wax' => 1, 'Gem Fragment' => 1 },
                       keys: { 'Wax' => item_key('wax1'), 'Gem Fragment' => 'group:1' }),
      game_recipe_hash(name: 'Bench', results: { 'Chair' => 1 }, ingredients: { 'Wax' => 1, 'Gem Fragment' => 1 },
                       keys: { 'Wax' => item_key('wax2'), 'Gem Fragment' => 'group:2' }),
      groups: [ { key: 'group:1', name: 'Gem Fragment', members: fragments },
                { key: 'group:2', name: 'Gem Fragment', members: fragments.to_a.reverse.to_h } ])
    recorder = GameKeyRecorder.new(import)
    expect(statuses(recorder)).to eq(item_key('wax1') => 'ambiguous', item_key('wax2') => 'ambiguous',
                                     'group:1' => 'record', 'group:2' => 'record')
    recorder.record!
    expect(gem.game_keys.pluck(:key)).to eq [ 'group:1', 'group:2' ]
  end

  it 'has nothing to record from an export without keys' do
    recipe = game_recipe_hash(name: 'Chair', ingredients: { 'Wax' => 1 })
    expect(GameKeyRecorder.new(import_of(recipe)).proposals).to be_empty
  end

  it 'lets the import match by key once recorded' do
    import = import_of(chair_recipe)
    GameKeyRecorder.new(import).record!
    wax.update!(name: 'Beeswax')
    expect(ItemLookup.new.id_for(import.entries.first.game_recipe.ingredients.last)).to eq wax.id
  end
end
