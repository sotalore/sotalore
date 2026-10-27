require 'rails_helper'

RSpec.describe GatheringNode do
  it 'takes a gathering skill, but not field dressing' do
    node = GatheringNode.new(name: 'Copper Vein', gathering_skill: CraftSkill.find('mining'))
    expect(node).to be_valid
    node.gathering_skill = CraftSkill.find('field_dressing')
    expect(node).not_to be_valid
    node.gathering_skill = CraftSkill.find('smelting')
    expect(node).not_to be_valid
    node.gathering_skill = nil
    expect(node).to be_valid
  end

  describe '#move_to_creatures!' do
    let(:kingsroad) { create(:scene, name: 'Kingsroad') }
    let(:hide) { create(:item, name: 'Animal Hide') }
    let(:suet) { create(:item, name: 'Suet') }
    let!(:node) { GatheringNode.create!(name: 'Grizzly Bear', notes: 'Field dressed, not mined.') }

    before do
      SceneNode.create!(scene: kingsroad, gathering_node: node)
      HarvestYield.create!(source: node, item: hide)
      HarvestYield.create!(source: node, item: suet)
    end

    it 'makes it a creature with its scenes, yields and notes' do
      creature = node.move_to_creatures!
      expect(creature).to eq Creature.find_by!(name: 'Grizzly Bear')
      expect(creature.scenes).to eq [ kingsroad ]
      expect(creature.yields).to eq [ hide, suet ]
      expect(creature.notes).to eq 'Field dressed, not mined.'
      expect(GatheringNode.exists?(node.id)).to be false
      expect(HarvestYield.where(source_type: 'GatheringNode')).to be_empty
    end

    it 'merges into a creature of that name' do
      bear = Creature.create!(name: 'Grizzly Bear', notes: 'Big.')
      SceneCreature.create!(scene: kingsroad, creature: bear, level_min: 20, level_max: 22)
      HarvestYield.create!(source: bear, item: hide)
      expect(node.move_to_creatures!).to eq bear
      expect(bear.reload.scene_creatures.sole.levels).to eq '20–22'
      expect(bear.yields).to eq [ hide, suet ]
      expect(bear.notes).to eq "Big.\n\nField dressed, not mined."
    end

    it 'is filed as a creature by later finds imports' do
      node.move_to_creatures!
      json = finds_json(finds_scene_hash(scene: 'Kingsroad', items: { 'Suet' => nil }, nodes: { 'Grizzly Bear' => [ 'Suet' ] }))
      import = FindsImport.create_from_json!(json)
      expect(import.analysis.scenes.sole.nodes.sole.creature?).to be true
      import.apply!
      expect(GatheringNode.exists?(name: 'Grizzly Bear')).to be false
    end
  end
end
