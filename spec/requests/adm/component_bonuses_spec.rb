require 'rails_helper'

RSpec.describe "Adm::ComponentBonuses", type: :request do
  let(:ingots) { %w[ Copper Iron Gold ].to_h { [ _1, create(:item, name: "#{_1} Ingot") ] } }

  # Copper, Iron and Gold Ingot as materials, and Dagger Blades and Mace Heads of
  # each, all captured but the Iron Mace Head.
  before do
    vein = GatheringNode.create!(name: 'Vein')
    sword = create(:item, name: 'Longsword', kind: :archetype)
    ingots.each do |metal, ingot|
      ore = create(:item, name: "#{metal} Ore").tap { HarvestYield.create!(source: vein, item: _1) }
      create(:recipe, craft_skill: 'smelting', with_ingredients: { ore => 4 }, with_results: { ingot => 1 })
      wire = create(:item, name: "Coil of #{metal} Wire")
      create(:recipe, craft_skill: 'smelting', with_ingredients: { ingot => 2 }, with_results: { wire => 1 })
      create(:recipe, craft_skill: 'tailoring', with_ingredients: { wire => 1 })
    end
    { 'Dagger Blade' => 2, 'Mace Head' => 3 }.each do |kind, count|
      group = create(:item, name: kind, kind: :group)
      create(:recipe, craft_skill: 'blacksmithing', with_ingredients: { group => 1 }, with_results: { sword => 1 })
      ingots.each do |metal, ingot|
        component = create(:item, name: "#{metal} #{kind}")
        ItemMembership.create!(group:, member: component)
        create(:recipe, craft_skill: 'blacksmithing', with_ingredients: { ingot => count }, with_results: { component => 1 })
        next if component.name == 'Iron Mace Head'
        component.game_keys.create!(key: item_key(component.name), name: component.name,
                                    catalog: { 'details' => { 'craftingBonus' => [ "+#{metal.size} Damage" ] } })
      end
    end
  end

  it 'shows the families of kinds and the evidence for them' do
    sign_in create(:user, :root)
    get adm_component_bonuses_path
    expect(response).to have_http_status(200)
    expect(response.body).to include('6 components: 5 captured, 1 inferred', 'Dagger Blade and Mace Head', '+4 Damage',
                                      'Dagger Blade and Mace Head: agree for Copper Ingot and Gold Ingot')
  end

  it 'is only for root' do
    sign_in create(:user)
    get adm_component_bonuses_path
    expect(response).not_to have_http_status(200)
  end

  it "shows a component's bonus from another of its family on its page" do
    get item_path(Item.find_by!(name: 'Iron Mace Head'))
    expect(response.body).to include('Crafting Bonus', '+4 Damage', 'Not captured from its own tooltip yet',
                                      'every Dagger Blade and Mace Head adds the same')
    get item_path(ingots['Iron'])
    expect(response.body).to include('Dagger Blade and Mace Head: +4 Damage')
  end
end
