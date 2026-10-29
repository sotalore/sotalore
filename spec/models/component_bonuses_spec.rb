require 'rails_helper'

RSpec.describe ComponentBonuses do
  let(:bonuses) { ComponentBonuses.new }
  let(:vein)    { GatheringNode.create!(name: 'Copper Vein') }
  let(:ingots)  { %w[ Copper Bronze Iron ].to_h { [ _1, create(:item, name: "#{_1} Ingot") ] } }
  let(:sword)   { create(:item, name: 'Longsword', kind: :archetype) }

  # A material for each ingot, refined from a gathered ore, Bronze from
  # Copper and Tin, and each refined again into wire.
  before do
    tin = create(:item, name: 'Tin Ore').tap { HarvestYield.create!(source: vein, item: _1) }
    %w[ Copper Iron ].each do |metal|
      ore = create(:item, name: "#{metal} Ore").tap { HarvestYield.create!(source: vein, item: _1) }
      create(:recipe, craft_skill: 'smelting', with_ingredients: { ore => 4 }, with_results: { ingots[metal] => 1 })
    end
    create(:recipe, craft_skill: 'smelting', with_ingredients: { ingots['Copper'] => 2, tin => 2 }, with_results: { ingots['Bronze'] => 1 })
    ingots.each do |metal, ingot|
      wire = create(:item, name: "Coil of #{metal} Wire")
      create(:recipe, craft_skill: 'smelting', with_ingredients: { ingot => 2 }, with_results: { wire => 1 })
      create(:recipe, craft_skill: 'tailoring', with_ingredients: { wire => 1 })
    end
  end

  # A group the sword's archetype recipe takes, with a component of each
  # ingot made by blacksmithing; +captured+ is { metal => bonus lines }.
  # Each kind's recipes take a different count, as a recipe's key comes
  # from what it takes.
  def kind(name, captured)
    count = @kinds = (@kinds || 1) + 1
    group = create(:item, name:, kind: :group)
    create(:recipe, craft_skill: 'blacksmithing', with_ingredients: { group => 1 }, with_results: { sword => 1 })
    ingots.to_h do |metal, ingot|
      component = create(:item, name: "#{metal} #{name}")
      ItemMembership.create!(group:, member: component)
      create(:recipe, craft_skill: 'blacksmithing', with_ingredients: { ingot => count }, with_results: { component => 1 })
      if captured.key?(metal)
        component.game_keys.create!(key: item_key(component.name), name: component.name,
                                    catalog: { 'details' => { 'craftingBonus' => captured[metal] } })
      end
      [ metal, component ]
    end
  end

  def item(name) = Item.find_by!(name:)

  it 'puts kinds that agree for enough materials in one family, and fills in what one has not captured' do
    kind('Dagger Blade', 'Copper' => [ '+1 Damage' ], 'Bronze' => [ '+3 Damage' ], 'Iron' => [ '+2 Damage' ])
    kind('Mace Head', 'Copper' => [ '+1 Damage' ], 'Bronze' => [ '+3 Damage' ])
    kind('Metal Hilt', 'Copper' => [ '+1 Damage' ], 'Bronze' => [ '+1% Crit' ])
    expect(bonuses.families.map { _1.kinds.map(&:name) }).to eq [ [ 'Dagger Blade', 'Mace Head' ], [ 'Metal Hilt' ] ]

    bonus = bonuses.for_item(item('Iron Mace Head'))
    expect(bonus).to have_attributes(lines: [ '+2 Damage' ])
    expect(bonus.from.item).to eq item('Iron Dagger Blade')
    expect(bonus.inferred?(item('Iron Mace Head'))).to be true
    expect(bonuses.for_item(item('Iron Metal Hilt'))).to be_nil
    expect(bonuses.for_item(item('Bronze Metal Hilt')).lines).to eq [ '+1% Crit' ]
  end

  it 'keeps apart kinds that agree for too few materials' do
    kind('Dagger Blade', 'Copper' => [ '+1 Damage' ], 'Bronze' => [ '+3 Damage' ])
    kind('Mace Head', 'Copper' => [ '+1 Damage' ])
    expect(bonuses.families.map { _1.kinds.size }).to eq [ 1, 1 ]
    expect(bonuses.for_item(item('Bronze Mace Head'))).to be_nil
  end

  it 'compares families by the stats they add, whatever the amounts' do
    kind('Dagger Blade', 'Copper' => [ '+1 Damage' ], 'Bronze' => [ '+3 Damage', '+5% Crit' ])
    kind('Two-handed Sword Blade', 'Copper' => [ '+2 Damage' ], 'Bronze' => [ '+5 Damage', '+8% Crit' ])
    kind('Metal Hilt', 'Copper' => [ '+1 Damage' ], 'Bronze' => [ '+3% Crit' ])
    blades, hilts = bonuses.family_comparisons.map { |c| [ c.families.map(&:name), c.same_stats?, c.size, c.same_stats.to_set ] }
                           .partition { _1[1] }
    expect(blades).to contain_exactly([ [ 'Two-handed Sword Blade', 'Dagger Blade' ], true, 'larger', ingots.values_at('Copper', 'Bronze').to_set ])
    expect(hilts).to contain_exactly(
      [ [ 'Dagger Blade', 'Metal Hilt' ], false, nil, Set[ingots['Copper']] ],
      [ [ 'Metal Hilt', 'Two-handed Sword Blade' ], false, nil, Set[ingots['Copper']] ]
    )
  end

  it 'says what each family adds for a material' do
    kind('Dagger Blade', 'Bronze' => [ '+3 Damage' ])
    kind('Metal Hilt', 'Bronze' => [ '+1% Crit' ], 'Copper' => [])
    expect(bonuses.for_material(ingots['Bronze']).map { |family, bonus| [ family.name, bonus.lines ] })
      .to contain_exactly([ 'Dagger Blade', [ '+3 Damage' ] ], [ 'Metal Hilt', [ '+1% Crit' ] ])
    expect(bonuses.for_material(ingots['Copper'])).to be_empty
  end

  it 'finds a material by name when there is no recipe' do
    hilts = kind('Metal Hilt', 'Copper' => [ '+1% Crit' ])
    hilts['Bronze'].recipes.destroy_all
    expect(bonuses.kind_for(hilts['Bronze']).components.find { _1.item == hilts['Bronze'] }.material).to eq ingots['Bronze']
  end

  it 'tells quickly whether an item is a component' do
    hilts = kind('Metal Hilt', {})
    expect(ComponentBonuses.component?(hilts['Iron'])).to be true
    expect(ComponentBonuses.component?(ingots['Iron'])).to be false
  end
end
