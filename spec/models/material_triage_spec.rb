require 'rails_helper'

RSpec.describe MaterialTriage do
  let(:wood)   { create(:item, name: 'Maple Wood', source: :gathering, gathering_skill: 'forestry') }
  let(:bark)   { create(:item, name: 'Sooty Bark', source: :recipe) }
  let(:timber) { create(:item, name: 'Maple Timber', source: :recipe) }
  let(:hard)   { create(:item, name: 'Hard Maple Timber', source: :unknown) }
  let(:handle) { create(:item, name: 'Hard Maple Handle') }
  let(:rug)    { create(:item, name: 'Big Rug') }
  let(:thread) { create(:item, name: 'Spool of Cotton Thread') }
  let(:tree)   { GatheringNode.create!(name: 'Maple Tree', gathering_skill: CraftSkill.find('forestry')) }
  let(:triage) { MaterialTriage.new }

  before do
    create(:recipe, craft_skill: 'milling', with_ingredients: { wood => 6 }, with_results: { timber => 2 })
    create(:recipe, craft_skill: 'milling', with_ingredients: { timber => 4, bark => 1 }, with_results: { hard => 1 })
    create(:recipe, craft_skill: 'carpentry', with_ingredients: { hard => 1 }, with_results: { handle => 1 })
    create(:recipe, craft_skill: 'textiles', with_ingredients: { thread => 30 }, with_results: { rug => 1 })
    HarvestYield.create!(source: tree, item: wood)
    HarvestYield.create!(source: tree, item: bark)
  end

  def issues_for(item) = triage.rows.find { _1.item == item }.issues

  it 'takes what refining that feeds production takes or makes' do
    expect(triage.rows.map(&:item)).to contain_exactly(wood, bark, timber, hard)
    expect(triage.by_skill.transform_keys(&:key).transform_values { _1.map(&:item) })
      .to eq('milling' => [ hard, timber, wood, bark ])
  end

  it 'finds nothing wrong where the stored values agree with the evidence' do
    expect(issues_for(wood)).to be_empty
    expect(issues_for(timber)).to be_empty
  end

  it 'suggests the gathering skill and source the evidence gives' do
    expect(issues_for(bark).map { [ _1.field, _1.fix, _1.fix_label ] })
      .to eq [ [ :gathering_skill, 'forestry', 'Set Forestry' ], [ :source, 'gathering', 'Set gathering' ] ]
    expect(issues_for(hard).map { [ _1.field, _1.fix ] }).to eq [ [ :source, 'recipe' ] ]
    expect(triage.with_issues.map(&:item)).to contain_exactly(bark, hard)
  end

  it 'clears a gathering skill on what recipes make and nothing gathers' do
    timber.update!(gathering_skill: 'forestry')
    expect(issues_for(timber).sole).to have_attributes(field: :gathering_skill, fix: nil, fix_label: 'Clear it')
  end

  it 'notes, without fixing, a stored source nothing confirms' do
    sinew = create(:item, name: 'Sinew', source: :gathering)
    create(:recipe, craft_skill: 'tanning', with_ingredients: { sinew => 1 }, with_results: { create(:item) => 1 })
      .tap { |r| create(:recipe, craft_skill: 'tailoring', with_ingredients: { r.results.first.item => 1 }) }
    expect(issues_for(sinew).sole).to have_attributes(field: :source, note: true, fixable?: false)
    expect(triage.with_issues.map(&:item)).not_to include(sinew)
    sinew.update!(gathering_skill: 'fishing')
    expect(MaterialTriage.new.rows.find { _1.item == sinew }.issues).to be_empty
  end

  it 'flags a node with no skill yet' do
    HarvestYield.create!(source: GatheringNode.create!(name: 'Odd Stump'), item: bark)
    expect(issues_for(bark).first).to have_attributes(field: :node, message: /Odd Stump/)
  end
end
