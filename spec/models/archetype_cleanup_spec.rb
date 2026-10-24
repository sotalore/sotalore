require 'rails_helper'

RSpec.describe ArchetypeCleanup do
  let(:coal)  { create :item, name: 'Chunk of Coal' }
  let(:blade) { create :item, name: 'Shortsword Blade', kind: :group }
  let(:hilt)  { create :item, name: 'Metal Hilt', kind: :group }
  let(:sword) { create :item, name: 'Shortsword', kind: :archetype }
  let!(:shortsword) do
    create :recipe, name: 'Shortsword', craft_skill: 'blacksmithing', game_id: 1,
                    with_ingredients: { coal => 3, blade => 1, hilt => 1 }, with_results: { sword => 1 }
  end

  let(:bronze_blade) { member(blade, 'Bronze Shortsword Blade') }
  let(:iron_hilt)    { member(hilt, 'Iron Hilt') }

  def member(group, name)
    create(:item, name: name).tap { ItemMembership.create!(group: group, member: _1) }
  end

  def old_recipe(name, ingredients, skill: 'blacksmithing')
    create :recipe, name: name, craft_skill: skill, with_ingredients: ingredients,
                    with_results: { create(:item, name: name) => 1 }
  end

  it 'finds old recipes named after an archetype, and says which fit its recipe' do
    fits = old_recipe('Bronze Shortsword with Iron Hilt', { coal => 5, bronze_blade => 1, iron_hilt => 1 })
    odd  = old_recipe('Crimson Shortsword of Haste', { create(:item, name: 'Crimson Blade') => 1, iron_hilt => 1 })
    old_recipe('Shortsword Half-Armor', { coal => 2, bronze_blade => 1, iron_hilt => 1 })
    old_recipe('Bronze Shortsword with Copper Hilt', { coal => 4, bronze_blade => 1, iron_hilt => 1 }, skill: 'carpentry')

    candidates = described_class.new.candidates
    expect(candidates.map(&:recipe)).to eq [ fits, odd ]
    expect(candidates.map(&:archetype_recipe).uniq).to eq [ shortsword ]
    expect(candidates.first).to be_fits
    expect(candidates.last.misfits).to eq [ "Crimson Blade isn't in the game's recipe", 'no Chunk of Coal', 'no Shortsword Blade' ]
  end

  it 'deletes the chosen recipes and the items only they make' do
    gone = old_recipe('Bronze Shortsword with Iron Hilt', { coal => 5, bronze_blade => 1, iron_hilt => 1 })
    keyed = old_recipe('Iron Shortsword with Iron Hilt', { coal => 4, member(blade, 'Iron Shortsword Blade') => 1, iron_hilt => 1 })
    keyed.results.first.item.game_keys.create!(key: item_key('iron-shortsword'), name: 'Iron Shortsword')
    kept = old_recipe('Copper Shortsword with Iron Hilt', { coal => 3, member(blade, 'Copper Shortsword Blade') => 1, iron_hilt => 1 })
    made = gone.results.first.item
    create :comment, subject: gone

    cleanup = described_class.new
    expect(cleanup.candidates.find { _1.recipe == keyed }.items.first.kept_because).to eq 'it has a game key'
    expect(cleanup.delete!([ gone.id.to_s, keyed.id.to_s, shortsword.id.to_s ])).to eq [ 2, 1 ]

    expect(Recipe.where(id: [ gone.id, keyed.id ])).to be_empty
    expect(Item.exists?(made.id)).to be false
    expect(keyed.results.first.item.reload).to be_present
    expect(Recipe.where(id: [ kept.id, shortsword.id ]).count).to eq 2
    expect(Comment.where(subject: gone)).to be_empty
  end
end
