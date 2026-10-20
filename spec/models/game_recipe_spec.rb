require 'rails_helper'

RSpec.describe GameRecipe do
  let(:hash) do
    game_recipe_hash(name: 'Accordion', id: 741803257, level: 40,
                     ingredients: { 'Wooden Board' => 8 }, tools: [ 'Wood Chisel' ])
  end
  subject { GameRecipe.new(hash) }

  it 'reads the export fields' do
    expect(subject.game_id).to eq 741803257
    expect(subject.name).to eq 'Accordion'
    expect(subject.craft_skill).to eq CraftSkill.find('carpentry')
    expect(subject.proficiency).to eq 40
    expect(subject.ingredients.map { [ _1.name, _1.count, _1.tool? ] }).to eq [
      [ 'Wooden Board', 8, false ],
      [ 'Wood Chisel', 1, true ],
    ]
    expect(subject.results.map { [ _1.name, _1.count ] }).to eq [ [ 'Accordion', 1 ] ]
    expect(subject.item_names).to eq [ 'Wooden Board', 'Wood Chisel', 'Accordion' ]
  end

  it 'has no craft skill for game categories the site lacks' do
    expect(GameRecipe.new(game_recipe_hash(name: 'X', category: 'ObsidianForge')).craft_skill).to be_nil
  end

  it 'reads game keys, group slots and stats' do
    board = item_key('board')
    gr = GameRecipe.new(game_recipe_hash(
      name: 'Accordion', ingredients: { 'Wooden Board' => 8, 'Wax' => 2 },
      keys: { 'Wooden Board' => 'group:7', 'Wax' => item_key('wax'), 'Accordion' => item_key('acc') },
      stats: { 'Accordion' => [ { 'key' => 'durability', 'value' => 100 } ] }))
    gr.payload['ingredients'][0]['choices'] = [ { 'key' => board, 'stats' => [] } ]
    gr = GameRecipe.new(gr.payload)

    slot, wax = gr.ingredients
    expect([ slot.key, slot.group?, slot.choice_keys ]).to eq [ 'group:7', true, [ board ] ]
    expect([ wax.key, wax.group? ]).to eq [ item_key('wax'), false ]
    expect(gr.results.first).to have_attributes(key: item_key('acc'),
                                                stats: [ { 'key' => 'durability', 'value' => 100 } ])
    expect(gr.lines.map(&:name)).to eq [ 'Wooden Board', 'Wax', 'Accordion' ]
  end

  it 'gives a recipe without a fixed result its first group slot as its result' do
    gr = GameRecipe.new(game_recipe_hash(
      name: 'Masterwork Carpentry Upgrade', results: {},
      ingredients: { 'Silver Ingot' => 5, 'Crafted Carpentry Equipable' => 1, 'Pattern' => 1 },
      keys: { 'Crafted Carpentry Equipable' => 'group:137', 'Pattern' => 'group:9' }))
    expect(gr).not_to be_fixed_results
    expect(gr.modification_target.key).to eq 'group:137'
    expect(gr.results.map { [ _1.name, _1.count, _1.key, _1.group? ] })
      .to eq [ [ 'Crafted Carpentry Equipable', 1, 'group:137', true ] ]
    expect(gr).to be_modification
  end

  it 'takes a placeholder ingredient as what a recipe changes, ahead of a later group slot' do
    hash = game_recipe_hash(name: 'Repair Item (Minor)', results: {},
                            ingredients: { 'Worn Item' => 1, 'Tailoring Repair Kit' => 1 },
                            keys: { 'Tailoring Repair Kit' => 'group:157' })
    hash['ingredients'][0]['stats'] = []
    gr = GameRecipe.new(hash)
    expect(gr.ingredients.first).to be_placeholder
    expect(gr.results.map { [ _1.name, _1.key ] }).to eq [ [ 'Worn Item', nil ] ]
    expect(gr).to be_modification

    salvage = game_recipe_hash(name: 'Salvage Item', results: {}, ingredients: { 'Salvageable Item' => 1 })
    salvage['ingredients'][0]['stats'] = []
    expect(GameRecipe.new(salvage).results.map(&:name)).to eq [ 'Salvageable Item' ]
  end

  it 'has no placeholders in files without keys' do
    gr = GameRecipe.new(game_recipe_hash(name: 'Beer Cask (Ale)', results: {}, ingredients: { 'Beer Cask' => 1 }))
    expect(gr.ingredients.first).not_to be_placeholder
  end

  it 'maps game categories the site names differently' do
    expect(GameRecipe.new(game_recipe_hash(name: 'Sow Seed', category: 'Farming')).craft_skill)
      .to eq CraftSkill.find('agriculture')
  end

  it 'has no result for a recipe without a fixed result or a group slot' do
    gr = GameRecipe.new(game_recipe_hash(name: 'Beer Cask (Ale)', results: {}, ingredients: { 'Beer Cask' => 1 }))
    expect([ gr.results, gr.modification_target, gr.modification? ]).to eq [ [], nil, false ]
  end

  it 'reads lines without keys from older exports' do
    expect(subject.lines.map(&:key)).to all(be_nil)
  end

  describe '.parse_export' do
    it 'parses a full export, with its groups' do
      export = GameRecipe.parse_export(game_export_json(
        hash, hash, groups: [ { key: 'group:7', name: 'Wooden Board', members: { item_key(1) => 'Oak Board' } } ]))
      expect([ export.api_version, export.recipes.size ]).to eq [ 26, 2 ]
      group = export.groups.first
      expect([ group.key, group.name, group.complete?, group.choice_count ]).to eq [ 'group:7', 'Wooden Board', true, 1 ]
      expect(group.members).to eq [ GameGroup::Member.new(item_key(1), 'Oak Board') ]
    end

    it "reads the file's scope, ignoring ones it doesn't know" do
      expect(GameRecipe.parse_export(game_export_json(hash, scope: 'all')).scope).to eq 'all'
      expect(GameRecipe.parse_export(game_export_json(hash, scope: 'everything')).scope).to be_nil
      expect(GameRecipe.parse_export(game_export_json(hash)).scope).to be_nil
    end

    it 'rejects other JSON, including a bare recipe' do
      expect { GameRecipe.parse_export('{"foo": 1}') }.to raise_error(ArgumentError)
      expect { GameRecipe.parse_export(hash.to_json) }.to raise_error(ArgumentError, /"recipes" list/)
      expect { GameRecipe.parse_export([ hash ].to_json) }.to raise_error(ArgumentError)
    end
  end
end
