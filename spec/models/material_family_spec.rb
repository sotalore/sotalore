require 'rails_helper'

RSpec.describe MaterialFamily do
  let(:ore)    { create(:item, name: 'Copper Ore') }
  let(:tin)    { create(:item, name: 'Tin Ore') }
  let(:copper) { create(:item, name: 'Copper Ingot') }
  let(:bronze) { create(:item, name: 'Bronze Ingot') }
  let(:family) { MaterialFamily.new('metal') }

  before do
    vein = GatheringNode.create!(name: 'Copper Vein', gathering_skill: CraftSkill.find('mining'))
    [ ore, tin ].each { HarvestYield.create!(source: vein, item: _1) }
    create(:recipe, craft_skill: 'smelting', with_ingredients: { ore => 4 }, with_results: { copper => 1 })
    create(:recipe, craft_skill: 'smelting', with_ingredients: { copper => 2, tin => 2 }, with_results: { bronze => 1 })
    wire = create(:item, name: 'Coil of Bronze Wire')
    create(:recipe, craft_skill: 'smelting', with_ingredients: { bronze => 2 }, with_results: { wire => 1 })
    create(:recipe, craft_skill: 'blacksmithing', with_ingredients: { wire => 1 })
  end

  it 'has the common and uncommon materials, and what is gathered for them by skill' do
    expect(family.commons.map(&:item)).to eq [ copper ]
    expect(family.uncommons.map(&:item)).to eq [ bronze ]
    expect(family.by_skill.map { [ _1.skill.key, _1.items ] }).to eq [ [ 'mining', [ ore, tin ] ] ]
    expect(family.additive?(tin)).to be true
    expect(family.additive?(ore)).to be false
    expect(MaterialFamily.new('wood').all).to be_empty
  end

  it 'traces the path of a material or something gathered' do
    expect(family.path(bronze)).to contain_exactly(bronze, copper, tin, ore)
    expect(family.path(copper)).to contain_exactly(copper, ore, bronze)
    expect(family.path(tin)).to contain_exactly(tin, bronze)
    expect(family.include?(tin)).to be true
    expect(family.include?(create(:item))).to be false
  end
end
