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
    expect(subject.ingredients.map(&:to_h)).to eq [
      { name: 'Wooden Board', count: 8, tool: false },
      { name: 'Wood Chisel', count: 1, tool: true },
    ]
    expect(subject.results.map { [ _1.name, _1.count ] }).to eq [ [ 'Accordion', 1 ] ]
    expect(subject.item_names).to eq [ 'Wooden Board', 'Wood Chisel', 'Accordion' ]
  end

  it 'has no craft skill for game categories the site lacks' do
    expect(GameRecipe.new(game_recipe_hash(name: 'X', category: 'ObsidianForge')).craft_skill).to be_nil
  end

  describe '.parse_export' do
    it 'parses a full export' do
      version, full, recipes = GameRecipe.parse_export(game_export_json(hash, hash))
      expect([ version, full, recipes.size ]).to eq [ 26, true, 2 ]
    end

    it 'parses a single recipe' do
      version, full, recipes = GameRecipe.parse_export(hash.to_json)
      expect([ version, full, recipes.map(&:name) ]).to eq [ nil, false, [ 'Accordion' ] ]
    end

    it 'rejects other JSON' do
      expect { GameRecipe.parse_export('{"foo": 1}') }.to raise_error(ArgumentError)
    end
  end
end
