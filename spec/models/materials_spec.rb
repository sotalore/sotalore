require 'rails_helper'

RSpec.describe Materials do
  let(:ore)    { create(:item, name: 'Copper Ore') }
  let(:tin)    { create(:item, name: 'Tin Ore') }
  let(:coal)   { create(:item, name: 'Chunk of Coal', use: :fuel) }
  let(:mold)   { create(:item, name: 'Ingot Mold', use: :tool) }
  let(:copper) { create(:item, name: 'Copper Ingot') }
  let(:bronze) { create(:item, name: 'Bronze Ingot') }
  let(:wire)   { create(:item, name: 'Coil of Bronze Wire') }
  let(:dye)    { create(:item, name: 'Red Dye') }
  let(:vein)   { GatheringNode.create!(name: 'Copper Vein', gathering_skill: CraftSkill.find('mining')) }
  let(:materials) { Materials.new }

  def smelt(takes, gives) = create(:recipe, craft_skill: 'smelting', with_ingredients: takes, with_results: gives)
  def smith(takes) = create(:recipe, craft_skill: 'blacksmithing', with_ingredients: takes)

  before do
    smelt({ mold => 1, ore => 4, coal => 1 }, { copper => 1 })
    smelt({ mold => 1, copper => 2, tin => 2, coal => 2 }, { bronze => 1 })
    smelt({ copper => 2, coal => 1 }, { create(:item, name: 'Coil of Copper Wire') => 1 })
    smelt({ bronze => 2, coal => 1 }, { wire => 1 })
    smith({ wire => 1 })
    smith({ copper => 1 })
    [ ore, tin, coal ].each { HarvestYield.create!(source: vein, item: _1) }
  end

  it 'finds the common materials, refined from gathered things, and the uncommon ones' do
    expect(materials.all.map { [ _1.item, _1.family, _1.tier ] })
      .to eq [ [ copper, 'metal', 'common' ], [ bronze, 'metal', 'uncommon' ] ]
    expect(materials.find(copper)).to have_attributes(raw: [ ore ], base: nil, additives: [])
    expect(materials.find(bronze)).to have_attributes(raw: [], base: copper, additives: [ tin ], forms: [ wire ])
    expect(materials.uncommon_of(materials.find(copper)).map(&:item)).to eq [ bronze ]
  end

  it 'tells what a form is a form of, and what raw goods and additives go into' do
    expect(materials.form_of(wire).item).to eq bronze
    expect(materials.form_of(ore)).to be_nil
    expect(materials.refined_into(ore).map(&:item)).to eq [ copper ]
    expect(materials.refined_into(tin).map(&:item)).to eq [ bronze ]
    expect(materials.refined_into(coal)).to be_empty
  end

  it 'leaves out what is refined from gathered things but not refined again' do
    bark = create(:item, name: 'Maple Tree Bark')
    HarvestYield.create!(source: vein, item: bark)
    create(:recipe, craft_skill: 'tanning', with_ingredients: { bark => 8, coal => 2 }, with_results: { dye => 1 })
    create(:recipe, craft_skill: 'tailoring', with_ingredients: { dye => 1 })
    expect(materials.find(dye)).to be_nil
  end

  it 'counts something also made from a material as its form' do
    bar = create(:item, name: 'Copper Bar')
    smelt({ ore => 4, coal => 1 }, { bar => 1 })
    smelt({ copper => 1, coal => 1 }, { bar => 1 })
    smelt({ bar => 3 }, { create(:item, name: 'Copper Blank') => 1 })
    smith({ bar => 1 })
    expect(materials.find(bar)).to be_nil
    expect(materials.form_of(bar).item).to eq copper
  end

  it 'counts only refining that feeds production' do
    Recipe.where(craft_skill: 'blacksmithing').destroy_all
    expect(materials.all).to be_empty
  end

  it 'says what one unit takes in gathered goods and fuel, through what it is refined from' do
    scrap = create(:item, name: 'Metal Scrap')
    smelt({ mold => 1, scrap => 12, ore => 2, coal => 1 }, { copper => 1 })
    expect(materials.recipe_for(materials.find(copper)).ingredients.map(&:item)).to contain_exactly(mold, ore, coal)
    expect(materials.takes_per_unit(materials.find(bronze))).to eq(ore => 8, tin => 2, coal => 4)
  end

  it 'tells quickly whether an item could be involved' do
    expect(Materials.involves?(tin)).to be true
    expect(Materials.involves?(create(:item))).to be false
  end
end
