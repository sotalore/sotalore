require 'rails_helper'

RSpec.describe ItemSources do
  let(:ingot) { create(:item, name: 'Copper Ingot') }
  let(:ore)   { create(:item, name: 'Copper Ore', source: :recipe, gathering_skill: nil) }
  let(:bark)  { create(:item, name: 'Sooty Bark') }
  let(:sources) { ItemSources.new(ore) }

  it 'knows nothing of an item with no records' do
    expect(sources.kinds).to be_empty
  end

  it 'reads crafting skills from the recipes that make it, not retired ones or modifications' do
    create(:recipe, craft_skill: 'smelting', with_ingredients: { ore => 4 }, with_results: { ingot => 1 })
    create(:recipe, craft_skill: 'blacksmithing', with_ingredients: { ore => 4 }, with_results: { ingot => 1 }, retired_at: Time.current)
    create(:recipe, craft_skill: 'alchemy', with_ingredients: { ingot => 1 }, with_results: { ingot => 1 })
    expect(ItemSources.new(ingot).crafting_skills.map(&:key)).to eq [ 'smelting' ]
    expect(ItemSources.new(ingot).kinds).to eq [ :crafted ]
  end

  it 'reads gathering skills from nodes and creatures seen yielding it' do
    vein = GatheringNode.create!(name: 'Copper Vein', gathering_skill: CraftSkill.find('mining'))
    pile = GatheringNode.create!(name: 'Odd Pile')
    HarvestYield.create!(source: vein, item: ore)
    HarvestYield.create!(source: pile, item: ore)
    HarvestYield.create!(source: Creature.create!(name: 'Rock Golem'), item: ore)
    expect(sources.gathering_skills.map(&:key)).to eq [ 'field_dressing', 'mining' ]
    expect(sources.unskilled_nodes).to eq [ pile ]
    expect(sources.kinds).to eq [ :gathered ]
  end

  it 'reads salvage, merchants and scenes' do
    bracelet = create(:item, name: 'Copper Bracelet')
    ItemSalvage.create!(salvage_from: bracelet, salvage_to: ore)
    ore.update!(merchant_price: 6)
    SceneFind.create!(scene: create(:scene), item: ore)
    expect(sources.salvaged_from).to eq [ bracelet ]
    expect(sources.kinds).to eq %i[ salvaged bought found ]
  end
end
