require 'rails_helper'

RSpec.describe ItemRoles do
  let(:ingot)  { create(:item, name: 'Bronze Ingot') }
  let(:ingots) { create(:item, name: 'Metal Ingot', kind: :group) }
  let(:any)    { create(:item, name: 'Any Metal', kind: :category) }
  let(:roles)  { ItemRoles.new(ingot) }

  before do
    ItemMembership.create!(group: ingots, member: ingot)
    ItemMembership.create!(group: any, member: ingot)
  end

  it 'has none when no recipe takes it' do
    expect(roles.kinds).to be_empty
  end

  it 'counts recipes taking it directly, or through its groups and categories, by kind of skill' do
    create(:recipe, craft_skill: 'smelting', with_ingredients: { ingot => 2 })
    create(:recipe, craft_skill: 'blacksmithing', with_ingredients: { ingots => 3 })
    create(:recipe, craft_skill: 'blacksmithing', with_ingredients: { any => 1 })
    create(:recipe, craft_skill: 'tailoring', with_ingredients: { ingots => 1 }, retired_at: Time.current)
    expect(roles.kinds).to eq %i[ refining production ]
    expect(roles.refining_counts.transform_keys(&:key)).to eq('smelting' => 1)
    expect(roles.production_counts.transform_keys(&:key)).to eq('blacksmithing' => 2)
    expect(roles.through.map { [ _1.group, _1.count ] }).to eq [ [ any, 1 ], [ ingots, 1 ] ]
  end

  it 'is a tool when a captured tooltip says so' do
    ingot.game_keys.create!(key: item_key('tongs'), name: ingot.name, catalog: { 'details' => { 'tool' => true } })
    expect(roles.kinds).to eq [ :tool ]
  end
end
