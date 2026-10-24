require 'rails_helper'

RSpec.describe ItemReview do
  let(:board) { create(:item, name: 'Wooden Board') }

  def row_for(item, filter:)
    ItemReview.new(filter: filter).rows.find { _1.item == item }
  end

  def suggestions(row)
    row.issues.map(&:suggest).compact
  end

  it 'flags an empty group' do
    group = create(:item, name: 'Pine or Maple Board', kind: :group)
    create(:recipe, name: 'Box', with_ingredients: { group => 1 }, with_results: { board => 1 })
    row = row_for(group, filter: 'group')
    expect(row.issues.map(&:message)).to eq [ 'No members yet' ]
  end

  it 'suggests category for a group no recipe calls for' do
    group = create(:item, name: 'Fish', kind: :group)
    ItemMembership.create!(group: group, member: create(:item, name: 'Trout'))
    row = row_for(group, filter: 'group')
    expect(row.issues.map(&:message)).to eq [ "No recipe calls for it, so it isn't a material choice" ]
    expect(suggestions(row)).to eq [ 'category' ]
  end

  it 'is happy with a category whatever uses it, with or without examples' do
    armor = create(:item, name: 'Back Slot Equipment', kind: :category)
    expect(row_for(armor, filter: 'category').issues).to be_empty
    ItemMembership.create!(group: armor, member: create(:item, name: 'Cloak'))
    expect(row_for(armor, filter: 'category')).to have_attributes(members: 1, issues: [])
  end

  it 'suggests archetype for a group a game recipe makes' do
    blade  = create(:item, name: 'Dagger Blade', kind: :group)
    dagger = create(:item, name: 'Dagger', kind: :group)
    create(:recipe, name: 'Dagger', game_id: 1, with_ingredients: { blade => 1, board => 1 },
                    with_results: { dagger => 1 })
    row = row_for(dagger, filter: 'abstract')
    expect(suggestions(row)).to eq [ 'archetype' ]
    expect(row.made_from_groups).to eq [ 'Dagger Blade' ]
    expect(row.game_result_uses).to eq 1
  end

  it 'suggests category for what a modification recipe takes and gives back' do
    equipable = create(:item, name: 'Crafted Carpentry Equipable')
    create(:recipe, name: 'Masterwork Carpentry Upgrade', with_ingredients: { equipable => 1, board => 1 },
                    with_results: { equipable => 1 })
    row = row_for(equipable, filter: 'suspect')
    expect(row).to be_modified
    expect(suggestions(row)).to eq [ 'category' ]
  end

  it 'finds concrete items named like groups' do
    either = create(:item, name: 'Copper or Iron Ingot')
    create(:item, name: 'Iron Ingot')
    rows = ItemReview.new(filter: 'suspect').rows
    expect(rows.map(&:item)).to eq [ either ]
    expect(suggestions(rows.first)).to eq [ 'group' ]
    expect(ItemReview.counts['suspect']).to eq 1
  end

  it 'suggests archetype for gear a game recipe makes from a group, but not for other things' do
    leather = create(:item, name: 'Yard of Leather', kind: :group)
    boots   = create(:item, name: 'Fortified Leather Boots', use: :armor)
    cloak   = create(:item, name: 'Cloak')
    chair   = create(:item, name: 'Arm Chair', use: :decoration)
    unknown = create(:item, name: 'Leather Helm', use: :armor)
    ItemMembership.create!(group: create(:item, name: 'Back Slot Equipment', kind: :category), member: cloak)
    create(:recipe, name: 'Boots', game_id: 1, with_ingredients: { leather => 1 }, with_results: { boots => 1 })
    create(:recipe, name: 'Cloak', game_id: 2, with_ingredients: { leather => 2 }, with_results: { cloak => 1 })
    create(:recipe, name: 'Chair', game_id: 3, with_ingredients: { leather => 3 }, with_results: { chair => 1 })
    create(:recipe, name: 'Helm', with_ingredients: { leather => 4 }, with_results: { unknown => 1 })

    expect(ItemReview.likely_archetypes).to contain_exactly(boots, cloak)
    expect(ItemReview.new(filter: 'suspect').rows.map(&:item)).to eq [ cloak, boots ]
    expect(suggestions(row_for(boots, filter: 'suspect'))).to eq [ 'archetype' ]
  end

  it 'suggests category for crafted-something names' do
    group = create(:item, name: 'Crafted Two-handed Weapon', kind: :group)
    concrete = create(:item, name: 'Crafted Chest Armor')
    expect(suggestions(row_for(group, filter: 'group'))).to eq [ 'category' ]
    expect(suggestions(row_for(concrete, filter: 'suspect'))).to eq [ 'category' ]
  end

  it 'suggests group for an archetype nothing makes' do
    archetype = create(:item, name: 'Thing', kind: :archetype)
    expect(suggestions(row_for(archetype, filter: 'archetype'))).to eq [ 'group' ]
  end

  it 'finds items active recipes use without a game key' do
    keyed = create(:item, name: 'Wax')
    keyed.game_keys.create!(key: item_key('wax'), name: 'Wax')
    unused = create(:item, name: 'Unused')
    group = create(:item, name: 'Metal Ingot', kind: :group)
    create(:recipe, name: 'Board', with_ingredients: { keyed => 1, group => 1 }, with_results: { board => 1 })
    create(:recipe, name: 'Gone', retired_at: Time.current, with_ingredients: { unused => 1 },
                    with_results: { unused => 1 })

    rows = ItemReview.new(filter: 'unkeyed').rows
    expect(rows.map(&:item)).to eq [ board ]
    expect(ItemReview.counts['unkeyed']).to eq 1
    keyed.update!(name: 'Wax or Tallow')
    expect(row_for(keyed, filter: 'suspect').game_keys).to eq 1
  end

  it 'lists items created since imports began, and can hide those without issues' do
    old = create(:item, name: 'Old', created_at: 2.days.ago)
    RecipeImport.create!(filename: 'x', created_at: 1.day.ago)
    fine = create(:item, name: 'Fine')
    odd  = create(:item, name: 'Fine or Dandy')
    expect(ItemReview.new(filter: 'recent').rows.map(&:item)).to eq [ odd, fine ]
    expect(ItemReview.new(filter: 'recent', issues_only: true).rows.map(&:item)).to eq [ odd ]
    expect(ItemReview.new(filter: 'recent').rows.map(&:item)).not_to include old
  end
end
