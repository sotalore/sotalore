require 'rails_helper'

RSpec.describe RecipeImport do
  let(:user) { create(:user, :root) }

  let!(:board)  { create(:item, name: 'Wooden Board') }
  let!(:wax)    { create(:item, name: 'Wax') }
  let!(:chisel) { create(:item, name: 'Wood Chisel', use: 'tool') }
  let!(:chair)  { create(:item, name: 'Chair') }
  let!(:bench)  { create(:item, name: 'Bench') }

  def import_of(*recipes)
    RecipeImport.create_from_json!(game_export_json(*recipes), filename: 'export.json', user: user)
  end

  def entry_named(import, name)
    import.entries.find_by!(name: name)
  end

  describe 'analysis' do
    it 'marks a recipe with no site match as an addition' do
      import = import_of(game_recipe_hash(name: 'Chair', ingredients: { 'Wooden Board' => 2 }))
      entry = entry_named(import, 'Chair')
      expect(entry).to be_addition
      expect(entry.recipe).to be_nil
    end

    it 'matches by name and finds no differences' do
      recipe = create(:recipe, name: 'Chair', craft_skill: 'carpentry', proficiency: 10,
                               with_ingredients: { board => 2, chisel => 1 }, with_results: { chair => 1 })
      import = import_of(game_recipe_hash(name: 'Chair', level: 10, ingredients: { 'Wooden Board' => 2 },
                                          tools: [ 'Wood Chisel' ]))
      entry = entry_named(import, 'Chair')
      expect(entry).to be_unchanged
      expect([ entry.recipe, entry.match_method ]).to eq [ recipe, 'name' ]
    end

    it 'records the differences of an outdated recipe' do
      create(:recipe, name: 'Chair', craft_skill: 'carpentry', proficiency: nil,
                      with_ingredients: { board => 1, wax => 3 }, with_results: { chair => 1 })
      import = import_of(game_recipe_hash(name: 'Chair', level: 20,
                                          ingredients: { 'Wooden Board' => 2 }, tools: [ 'Wood Chisel' ]))
      entry = entry_named(import, 'Chair')
      expect(entry).to be_outdated
      expect(entry.diff).to eq(
        'proficiency' => [ nil, 20 ],
        'ingredients' => {
          'added' => [ [ 'Wood Chisel', 1 ] ],
          'removed' => [ [ 'Wax', 3 ] ],
          'changed' => [ [ 'Wooden Board', 1, 2 ] ],
        })
    end

    it 'matches a renamed recipe by identical ingredients' do
      recipe = create(:recipe, name: 'Plain Bench', craft_skill: 'carpentry', proficiency: 1,
                               with_ingredients: { board => 3 }, with_results: { bench => 1 })
      import = import_of(game_recipe_hash(name: 'Bench', ingredients: { 'Wooden Board' => 3 }))
      entry = entry_named(import, 'Bench')
      expect([ entry.recipe, entry.match_method ]).to eq [ recipe, 'ingredients' ]
      expect(entry.diff).to eq('name' => [ 'Plain Bench', 'Bench' ])
    end

    it 'matches by the only same-skill recipe making the same result' do
      recipe = create(:recipe, name: 'Old Chair', craft_skill: 'carpentry',
                               with_ingredients: { wax => 1 }, with_results: { chair => 1 })
      import = import_of(game_recipe_hash(name: 'New Chair', results: { 'Chair' => 1 },
                                          ingredients: { 'Wooden Board' => 2 }))
      expect(entry_named(import, 'New Chair')).to have_attributes(recipe: recipe, match_method: 'result')
    end

    it 'prefers the game id, and never name-matches a recipe synced to another game recipe' do
      synced = create(:recipe, name: 'Chair', craft_skill: 'carpentry', game_id: 111,
                               with_ingredients: { board => 2 }, with_results: { chair => 1 })
      import = import_of(
        game_recipe_hash(name: 'Chair', id: 222, ingredients: { 'Wooden Board' => 5 }),
        game_recipe_hash(name: 'Fancy Chair', id: 111, results: { 'Chair' => 1 }, ingredients: { 'Wooden Board' => 2 })
      )
      expect(entry_named(import, 'Fancy Chair')).to have_attributes(recipe: synced, match_method: 'game_id')
      expect(entry_named(import, 'Chair').recipe).to be_nil
    end

    it 'blocks entries with unknown items or skills' do
      import = import_of(
        game_recipe_hash(name: 'Mystery', ingredients: { 'Unobtainium' => 1 }),
        game_recipe_hash(name: 'Obsidian Thing', category: 'ObsidianForge', ingredients: { 'Wax' => 1 })
      )
      expect(entry_named(import, 'Mystery')).to be_blocked
      expect(entry_named(import, 'Mystery').problems.join).to include 'Unknown items: Unobtainium, Mystery'
      expect(entry_named(import, 'Obsidian Thing').problems.join).to include 'ObsidianForge'
    end

    it 'never matches a template recipe to a game recipe making a concrete item' do
      group = create(:item, name: 'Fancy Chair', kind: :group)
      create(:recipe, name: 'Fancy Chair', craft_skill: 'carpentry',
                      with_ingredients: { board => 2 }, with_results: { group => 1 })
      import = import_of(game_recipe_hash(name: 'Fancy Chair', results: { 'Chair' => 1 },
                                          ingredients: { 'Wooden Board' => 2 }))
      entry = entry_named(import, 'Fancy Chair')
      expect(entry.recipe).to be_nil
    end

    it 'matches an archetype recipe to a game recipe making the same archetype' do
      blade  = create(:item, name: 'Dagger Blade', kind: :group)
      dagger = create(:item, name: 'Dagger', kind: :archetype)
      recipe = create(:recipe, name: 'Dagger', craft_skill: 'carpentry', proficiency: 30,
                               with_ingredients: { blade => 1, board => 1 }, with_results: { dagger => 1 })
      import = import_of(game_recipe_hash(name: 'Dagger', level: 30,
                                          ingredients: { 'Dagger Blade' => 1, 'Wooden Board' => 1 }))
      entry = entry_named(import, 'Dagger')
      expect(entry).to be_unchanged
      expect(entry.recipe).to eq recipe
    end

    it 'matches by name only within the same kind' do
      dagger = create(:item, name: 'Dagger', kind: :archetype)
      create(:recipe, name: 'Dagger', craft_skill: 'carpentry', with_ingredients: { board => 2 },
                      with_results: { chair => 1 })
      create(:recipe, name: 'Bench', craft_skill: 'carpentry', with_ingredients: { wax => 2 },
                      with_results: { dagger => 1 })
      import = import_of(game_recipe_hash(name: 'Dagger', results: { 'Dagger' => 1 }, ingredients: { 'Wooden Board' => 3 }),
                         game_recipe_hash(name: 'Bench', results: { 'Bench' => 1 }, ingredients: { 'Wax' => 3 }))
      expect(entry_named(import, 'Dagger').recipe&.name).to eq 'Bench'
      expect(entry_named(import, 'Bench').recipe).to be_nil
    end

    it 'matches a modification to a modification' do
      equipable = create(:item, name: 'Crafted Carpentry Equipable', kind: :category)
      recipe = create(:recipe, name: 'Masterwork Carpentry Upgrade', craft_skill: 'carpentry', proficiency: 80,
                               with_ingredients: { equipable => 1, wax => 2 }, with_results: { equipable => 1 })
      import = import_of(game_recipe_hash(name: 'Masterwork Carpentry Upgrade', level: 80,
                                          ingredients: { 'Crafted Carpentry Equipable' => 1, 'Wax' => 2 },
                                          results: { 'Crafted Carpentry Equipable' => 1 }))
      entry = entry_named(import, 'Masterwork Carpentry Upgrade')
      expect(entry).to be_unchanged
      expect(entry.recipe).to eq recipe
    end

    it 'blocks a game recipe making a group, unless it modifies it' do
      group = create(:item, name: 'Metal Equipment', kind: :group)
      create(:item, name: 'Dagger Blade', kind: :group)
      import = import_of(game_recipe_hash(name: 'Dagger Blade', ingredients: { 'Wax' => 1 }),
                         game_recipe_hash(name: 'Polish', ingredients: { 'Metal Equipment' => 1, 'Wax' => 1 },
                                          results: { 'Metal Equipment' => 1 }))
      expect(entry_named(import, 'Dagger Blade')).to be_blocked
      expect(entry_named(import, 'Dagger Blade').problems.join).to include "the game doesn't make groups"
      expect(entry_named(import, 'Polish')).to be_addition
      expect(group).to be_group
    end

    it 'matches by name while results are unknown, unless the site recipe is a template' do
      recipe = create(:recipe, name: 'Bench', craft_skill: 'carpentry', with_ingredients: { board => 3 },
                               with_results: { bench => 1 })
      import = import_of(game_recipe_hash(name: 'Bench', results: { 'Sturdy Bench' => 1 },
                                          ingredients: { 'Wooden Board' => 3 }))
      expect(entry_named(import, 'Bench').recipe).to eq recipe
    end

    it 'resolves items by alias' do
      ItemAlias.create!(name: 'Pine Board', item: board)
      import = import_of(game_recipe_hash(name: 'Chair', ingredients: { 'Pine Board' => 2 }))
      expect(entry_named(import, 'Chair')).to be_addition
    end
  end

  describe 'applying' do
    let(:applier) { RecipeImportApplier.new(user) }

    it 'creates a new recipe, linked to the game and verified' do
      import = import_of(game_recipe_hash(name: 'Chair', id: 42, level: 30,
                                          ingredients: { 'Wooden Board' => 2 }, tools: [ 'Wood Chisel' ]))
      entry = entry_named(import, 'Chair')
      expect(applier.apply(entry)).to be true

      recipe = entry.reload.recipe
      expect(entry).to be_applied
      expect(recipe).to have_attributes(name: 'Chair', game_id: 42, proficiency: 30,
                                        last_verified_by_id: user.id)
      expect(recipe.craft_skill.key).to eq 'carpentry'
      expect(recipe.ingredients.map { [ _1.name, _1.count ] }).to contain_exactly([ 'Wooden Board', 2 ], [ 'Wood Chisel', 1 ])
      expect(recipe.results.map { [ _1.name, _1.count ] }).to eq [ [ 'Chair', 1 ] ]
    end

    it 'updates an outdated recipe, recording a revision' do
      recipe = create(:recipe, name: 'Chair', craft_skill: 'carpentry',
                               with_ingredients: { board => 1, wax => 3 }, with_results: { chair => 1 })
      recipe.update_columns(retired_at: 1.day.ago)
      import = import_of(game_recipe_hash(name: 'Chair', level: 20, ingredients: { 'Wooden Board' => 2 }))
      entry = entry_named(import, 'Chair')

      expect { applier.apply(entry) }.to change { recipe.comments.count }.by(1)
      recipe.reload
      expect(recipe.ingredients.map { [ _1.name, _1.count ] }).to eq [ [ 'Wooden Board', 2 ] ]
      expect(recipe.proficiency).to eq 20
      expect(recipe).not_to be_retired
      body = JSON.parse(recipe.comments.last.body)
      expect(body['ingredient_changes']).to eq('removed' => [ [ 'Wax', 3 ] ], 'changes' => { 'Wooden Board' => [ 1, 2 ] })
    end

    it 'links an unchanged recipe without a revision' do
      recipe = create(:recipe, name: 'Chair', craft_skill: 'carpentry', proficiency: 1,
                               with_ingredients: { board => 2 }, with_results: { chair => 1 })
      import = import_of(game_recipe_hash(name: 'Chair', id: 7, ingredients: { 'Wooden Board' => 2 }))
      expect { applier.apply(entry_named(import, 'Chair')) }.not_to change { Comment.count }
      expect(recipe.reload).to have_attributes(game_id: 7, verified?: true)
    end

    it 'blocks the entry when the recipe cannot be saved' do
      import = import_of(game_recipe_hash(name: 'Chair', ingredients: { 'Wooden Board' => 2 }))
      entry = entry_named(import, 'Chair')
      create(:recipe, name: 'Other', craft_skill: 'carpentry',
                      with_ingredients: { board => 2 }, with_results: { bench => 1 }, game_id: 9)

      expect(applier.apply(entry)).to be false
      expect(entry.reload).to be_blocked
      expect(entry.problems.join).to include 'already exists as "Other"'
    end
  end

  describe 'RecipeImportEntry.using_item' do
    it 'finds entries using an item as an ingredient, tool or result' do
      import = import_of(
        game_recipe_hash(name: 'Chair', ingredients: { 'Wooden Board' => 2 }, tools: [ 'Wood Chisel' ]),
        game_recipe_hash(name: 'Bench', ingredients: { 'Wax' => 1 })
      )
      expect(import.entries.using_item('Wooden Board').map(&:name)).to eq [ 'Chair' ]
      expect(import.entries.using_item('Wood Chisel').map(&:name)).to eq [ 'Chair' ]
      expect(import.entries.using_item('Bench').map(&:name)).to eq [ 'Bench' ]
      expect(import.entries.using_item('Nothing')).to be_empty
    end
  end

  describe '#stale_recipes' do
    it 'lists active site recipes no entry matched' do
      matched = create(:recipe, name: 'Chair', with_ingredients: { board => 1 }, with_results: { chair => 1 })
      stale   = create(:recipe, name: 'Gone', with_ingredients: { wax => 1 })
      create(:recipe, name: 'Already retired', retired_at: 1.day.ago, with_ingredients: { wax => 2 })
      group = create(:item, name: 'Seat', kind: :group)
      create(:recipe, name: 'Seat', with_ingredients: { wax => 3 }, with_results: { group => 1 })
      dagger = create(:item, name: 'Dagger', kind: :archetype)
      gone_archetype = create(:recipe, name: 'Dagger', with_ingredients: { wax => 4 }, with_results: { dagger => 1 })
      import = import_of(game_recipe_hash(name: 'Chair', ingredients: { 'Wooden Board' => 2 }))
      expect(import.entries.first.recipe).to eq matched
      expect(import.stale_recipes).to contain_exactly(stale, gone_archetype)
    end
  end
end
