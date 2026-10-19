require 'rails_helper'

RSpec.describe FindsImport do
  let!(:kingsroad) { create(:scene, name: 'Kingsroad', pvp: false) }
  let!(:hide)      { create(:item, name: 'Animal Hide') }
  let!(:ore)       { create(:item, name: 'Copper Ore') }
  let!(:scrap)     { create(:item, name: 'Leather Scrap') }

  let(:scene_hash) do
    finds_scene_hash(scene: 'Kingsroad', raw_name: 'HiddenVale_Road',
                     items: { 'Animal Hide' => item_key('hide'), 'Copper Ore' => item_key('ore'),
                              'Leather Scrap' => item_key('scrap'), 'Wolf Pelt' => item_key('pelt'),
                              '[u]Undelivered Letter[/u]' => nil },
                     creatures: { 'Rabbit' => [ nil, nil ], 'Brown Bear' => [ 18, 18 ] },
                     nodes: { 'Copper Vein' => [ 'Copper Ore' ], 'Rabbit' => [ 'Leather Scrap', 'Animal Hide' ] },
                     info: { 'isPvp' => true, 'isDungeon' => false, 'isOverworld' => false, 'isPot' => false })
  end
  let(:import) { FindsImport.create_from_json!(finds_json(scene_hash), filename: 'sotalore-finds.json') }

  it 'rejects files that are not finds' do
    expect { FindsImport.create_from_json!({ recipes: [] }.to_json) }.to raise_error(ArgumentError)
    expect { FindsImport.create_from_json!({ scenes: [] }.to_json) }.to raise_error(ArgumentError, /No scenes/)
    expect { FindsImport.create_from_json!({ type: 'items', scenes: [ scene_hash ] }.to_json) }
      .to raise_error(ArgumentError, 'That file holds items, not finds')
  end

  describe 'analysis' do
    subject(:analysis) { import.analysis }

    it 'matches scenes and items, and tells field dressing from nodes' do
      row = analysis.scenes.sole
      expect(row.scene).to eq kingsroad
      expect(row.unknown_items.map { _1.game_item.name }).to eq [ 'Wolf Pelt', 'Undelivered Letter' ]
      expect(row.nodes.map { [ _1.name, _1.creature? ] }).to eq [ [ 'Copper Vein', false ], [ 'Rabbit', true ] ]
      expect(row.nodes.last.items.map(&:item)).to eq [ scrap, hide ]
      expect(row.differences).to eq [ [ 'PvP', false, true ] ]
      expect(analysis.new_creatures).to eq [ 'Brown Bear', 'Rabbit' ]
      expect(analysis.new_nodes).to eq [ 'Copper Vein' ]
    end

    it 'lists scenes the site lacks' do
      other = FindsImport.create_from_json!(finds_json(finds_scene_hash(scene: 'Nowhere', items: { 'Animal Hide' => nil })))
      expect(other.analysis.unmatched_scenes.map { _1.game.name }).to eq [ 'Nowhere' ]
    end
  end

  describe 'applying' do
    it 'records what can be found where, once' do
      expect(import.apply!).to eq(items: 3, creatures: 2, nodes: 1, yields: 3)
      expect(kingsroad.reload.game_name).to eq 'HiddenVale_Road'
      expect(kingsroad.finds_imported_at).to be_within(1.minute).of(Time.current)
      expect(kingsroad.found_items).to eq [ hide, ore, scrap ]
      expect(kingsroad.creatures.map(&:name)).to eq [ 'Brown Bear', 'Rabbit' ]
      expect(kingsroad.scene_creatures.find_by(creature: Creature.find_by!(name: 'Brown Bear')).levels).to eq '18'
      expect(Creature.find_by!(name: 'Rabbit').yields).to eq [ hide, scrap ]
      expect(GatheringNode.find_by!(name: 'Copper Vein').yields).to eq [ ore ]
      expect(hide.game_keys.pluck(:key)).to eq [ item_key('hide') ]
      expect(import.reload.applied_at).to be_present

      expect(FindsImport.find(import.id).apply!).to be_empty
    end

    it 'widens the level range seen' do
      import.apply!
      wider = scene_hash.merge('creatures' => [ { 'name' => 'Brown Bear', 'levelMin' => 15, 'levelMax' => 20 } ])
      FindsImport.create_from_json!(finds_json(wider)).apply!
      bear = Creature.find_by!(name: 'Brown Bear')
      expect(kingsroad.scene_creatures.find_by!(creature: bear).levels).to eq '15–20'
    end

    it 'matches a scene by its game name once recorded' do
      import.apply!
      renamed = finds_scene_hash(scene: 'King\'s Road', raw_name: 'HiddenVale_Road', items: { 'Animal Hide' => nil })
      expect(FindsImport.create_from_json!(finds_json(renamed)).analysis.scenes.sole.scene).to eq kingsroad
    end
  end

  describe 'resolving' do
    it 'creates unknown items with their keys' do
      item = import.create_item!(name: 'Wolf Pelt', key: item_key('pelt'))
      expect(item).to have_attributes(name: 'Wolf Pelt', kind: 'concrete')
      expect(item.game_keys.pluck(:key)).to eq [ item_key('pelt') ]
      expect(import.reload.analysis.unknown_items.map(&:name)).to eq [ 'Undelivered Letter' ]
      expect { import.create_item!(name: 'Animal Hide') }.to raise_error(FindsImport::Error)
    end

    it 'uses existing items, by key or by alias' do
      pelt = create(:item, name: 'Grey Wolf Pelt')
      import.use_item!(pelt, name: 'Wolf Pelt', key: item_key('pelt'))
      expect(pelt.game_keys.pluck(:key)).to eq [ item_key('pelt') ]
      letter = create(:item, name: 'Letter')
      import.reload.use_item!(letter, name: 'Undelivered Letter')
      expect(letter.aliases.pluck(:name)).to eq [ 'Undelivered Letter' ]
      expect(import.reload.analysis.unknown_items).to be_empty
    end

    it 'links an unmatched scene by its game name' do
      other = FindsImport.create_from_json!(finds_json(finds_scene_hash(scene: 'Nowhere', raw_name: 'Raw_Nowhere')))
      somewhere = create(:scene, name: 'Somewhere')
      other.link_scene!('Nowhere', somewhere)
      expect(somewhere.reload.game_name).to eq 'Raw_Nowhere'
      expect(other.reload.analysis.scenes.sole.scene).to eq somewhere
    end
  end
end
