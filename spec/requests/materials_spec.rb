require 'rails_helper'

RSpec.describe "Materials", type: :request do
  let(:ore)    { create(:item, name: 'Copper Ore') }
  let(:tin)    { create(:item, name: 'Tin Ore') }
  let(:copper) { create(:item, name: 'Copper Ingot') }
  let(:bronze) { create(:item, name: 'Bronze Ingot') }

  before do
    vein = GatheringNode.create!(name: 'Copper Vein', gathering_skill: CraftSkill.find('mining'))
    [ ore, tin ].each { HarvestYield.create!(source: vein, item: _1) }
    create(:recipe, craft_skill: 'smelting', with_ingredients: { ore => 4 }, with_results: { copper => 1 })
    create(:recipe, craft_skill: 'smelting', proficiency: 30, with_ingredients: { copper => 2, tin => 2 }, with_results: { bronze => 1 })
    wire = create(:item, name: 'Coil of Bronze Wire')
    create(:recipe, craft_skill: 'smelting', with_ingredients: { bronze => 2 }, with_results: { wire => 1 })
    create(:recipe, craft_skill: 'blacksmithing', with_ingredients: { wire => 1 })
  end

  it 'shows a family, gathered by skill, without where it is found' do
    get materials_path
    expect(response).to have_http_status(200)
    expect(response.body).to include('Mining', 'Copper Ore', 'Copper Ingot', 'Copper Ingot + Tin Ore', 'Pick anything')
    expect(response.body).not_to include('Copper Vein')
    get materials_path(family: 'wood')
    expect(response).to have_http_status(200)
  end

  it 'shows a picked material in full' do
    get materials_path(family: 'metal', item: bronze.id)
    expect(response.body).to include('Uncommon metal, refined from', 'by Smelting at level 30',
                                      'One Bronze Ingot takes 8 Copper Ore and 2 Tin Ore',
                                      'Refined further into', 'Production takes it, or its forms, in 1 Blacksmithing recipe')
  end

  it 'shows where something gathered comes from, to those who may see finds' do
    get materials_path(family: 'metal', item: tin.id)
    expect(response.body).to include('Gathered by Mining', 'An additive to')
    expect(response.body).not_to include('Copper Vein')
    sign_in create(:user, :root)
    get materials_path(family: 'metal', item: tin.id)
    expect(response.body).to include('Copper Vein')
  end

  it 'ignores a picked item from another family' do
    get materials_path(family: 'wood', item: bronze.id)
    expect(response.body).to include('Pick anything')
  end
end
