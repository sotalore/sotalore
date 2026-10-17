require 'rails_helper'

RSpec.describe "Adm::RecipeImports", type: :request do
  let(:user) { create(:user, :root) }
  before { sign_in user }

  let!(:board) { create(:item, name: 'Wooden Board') }
  let!(:chair) { create(:item, name: 'Chair') }
  let!(:citrine) { create(:item, name: 'Citrine') }
  let!(:outdated) do
    create(:recipe, name: 'Chair', craft_skill: 'carpentry',
                    with_ingredients: { board => 1 }, with_results: { chair => 1 })
  end
  let!(:stale) { create(:recipe, name: 'Old Ring', with_ingredients: { citrine => 9 }) }

  let(:json) do
    game_export_json(
      game_recipe_hash(name: 'Chair', id: 1, level: 10, ingredients: { 'Wooden Board' => 2 }),
      game_recipe_hash(name: 'Ring', id: 2, ingredients: { 'Citrine (Unrefined Gemstone)' => 1 })
    )
  end
  let(:import) { RecipeImport.create_from_json!(json, filename: 'export.json', user: user) }
  let(:chair_entry) { import.entries.find_by!(name: 'Chair') }
  let(:ring_entry) { import.entries.find_by!(name: 'Ring') }

  def upload(content, full_export: nil)
    file = Rack::Test::UploadedFile.new(StringIO.new(content), 'application/json',
                                        original_filename: 'export.json')
    post adm_recipe_imports_path, params: { file: file, full_export: full_export }.compact
  end

  it 'requires a root user' do
    sign_in create(:user, :editor)
    get adm_recipe_imports_path
    expect(response).to redirect_to(root_path)
  end

  describe 'uploading' do
    it 'imports and analyzes an export' do
      expect { upload(json) }.to change(RecipeImport, :count).by(1)
      import = RecipeImport.last
      expect(response).to redirect_to(adm_recipe_import_path(import))
      expect(import.status_counts).to include('outdated' => 1, 'blocked' => 1)
      expect(import.uploaded_by).to eq user
    end

    it 'is a full export only when the uploader says so' do
      upload(json)
      expect(RecipeImport.last.full_export).to be false
      upload(json, full_export: '1')
      expect(RecipeImport.last.full_export).to be true
    end

    it "goes by the file's scope when it has one" do
      recipes = [ game_recipe_hash(name: 'Chair', id: 1), game_recipe_hash(name: 'Bench', id: 2) ]
      upload(game_export_json(*recipes, scope: 'all'))
      expect(RecipeImport.last).to have_attributes(full_export: true, export_scope: 'all')

      upload(game_export_json(*recipes, scope: 'new'), full_export: '1')
      new_only = RecipeImport.last
      expect(new_only).to have_attributes(full_export: false, export_scope: 'new')
      get adm_recipe_import_path(new_only)
      expect(response.body).to include('file scope: new')
      expect(response.body).not_to include('Mark as full export')
      post set_full_export_adm_recipe_import_path(new_only), params: { full_export: '1' }
      expect(flash[:alert]).to eq %(It can't be a full export: the file says it holds "new" recipes.)
      expect(new_only.reload.full_export).to be false
    end

    it 'never takes a single recipe for a full export' do
      upload(game_export_json(game_recipe_hash(name: 'Chair', id: 9)), full_export: '1')
      expect(RecipeImport.last.full_export).to be false
    end

    it 'marks an import full or partial' do
      post set_full_export_adm_recipe_import_path(import), params: { full_export: '1' }
      expect(import.reload.full_export).to be true
      post set_full_export_adm_recipe_import_path(import), params: { full_export: '0' }
      expect(import.reload.full_export).to be false

      single = RecipeImport.create_from_json!(game_export_json(game_recipe_hash(name: 'Chair', id: 9)), user: user)
      post set_full_export_adm_recipe_import_path(single), params: { full_export: '1' }
      expect(flash[:alert]).to eq "It can't be a full export: a single recipe."
      expect(single.reload.full_export).to be false
    end

    it 'imports a pasted recipe and goes straight to it' do
      pasted = game_recipe_hash(name: 'Bark Bread', id: -1599494009, category: 'Cooking',
                                ingredients: { 'Wooden Board' => 2 }, results: { 'Bark Bread' => 4 }).to_json
      expect { post adm_recipe_imports_path, params: { json: "  #{pasted}\n" } }
        .to change(RecipeImport, :count).by(1)
      import = RecipeImport.last
      entry = import.entries.sole
      expect(response).to redirect_to(adm_recipe_import_entry_path(import, entry))
      expect(import).to have_attributes(filename: 'Pasted: Bark Bread', full_export: false)
      expect(entry).to have_attributes(name: 'Bark Bread', game_id: -1599494009)
    end

    it 'labels a pasted list by its recipes' do
      post adm_recipe_imports_path, params: { json: json }
      expect(RecipeImport.last.filename).to eq 'Pasted: Chair + 1 more'
      expect(response).to redirect_to(adm_recipe_import_path(RecipeImport.last))
    end

    it 'rejects pasted junk or nothing' do
      expect { post adm_recipe_imports_path, params: { json: '{"name": "Bark Bread"' } }
        .not_to change(RecipeImport, :count)
      expect(flash[:alert]).to include "Couldn't import"

      post adm_recipe_imports_path, params: { json: game_recipe_hash(name: 'X').except('id').to_json }
      expect(flash[:alert]).to include 'needs an "id"'

      post adm_recipe_imports_path, params: { json: '  ' }
      expect(flash[:alert]).to include 'paste recipe JSON'
    end

    it 'rejects junk' do
      expect { upload('not json') }.not_to change(RecipeImport, :count)
      expect(response).to redirect_to(adm_recipe_imports_path)
      expect(flash[:alert]).to include "Couldn't import"
    end
  end

  it 'lists imports' do
    import
    get adm_recipe_imports_path
    expect(response).to have_http_status(200)
    expect(response.body).to include 'export.json'
  end

  it 'shows an import, filtered by status' do
    get adm_recipe_import_path(import, status: 'outdated')
    expect(response).to have_http_status(200)
    expect(response.body).to include 'Chair'
    expect(response.body).not_to include 'Unknown items: Citrine'
  end

  it 'filters entries by an item they use' do
    get adm_recipe_import_path(import, item: 'Citrine (Unrefined Gemstone)')
    expect(response).to have_http_status(200)
    expect(response.body).to include adm_recipe_import_entry_path(import, ring_entry)
    expect(response.body).not_to include adm_recipe_import_entry_path(import, chair_entry)
  end

  it 'shows an entry' do
    get adm_recipe_import_entry_path(import, chair_entry)
    expect(response).to have_http_status(200)
    expect(response.body).to include 'Applying will change'
  end

  it 'applies an entry' do
    post apply_adm_recipe_import_entry_path(import, chair_entry)
    expect(chair_entry.reload).to be_applied
    expect(outdated.reload.proficiency).to eq 10
  end

  it 'applies all entries of a status' do
    post apply_all_adm_recipe_import_path(import), params: { status: 'outdated' }
    expect(response).to redirect_to(adm_recipe_import_path(import, status: 'outdated'))
    expect(flash[:notice]).to include 'Applied 1 of 1'
    expect(outdated.reload.game_id).to eq 1
  end

  it 'skips and unskips an entry' do
    post skip_adm_recipe_import_entry_path(import, chair_entry)
    expect(chair_entry.reload).to be_skipped
    post unskip_adm_recipe_import_entry_path(import, chair_entry)
    expect(chair_entry.reload).to be_outdated
  end

  it 'links an entry to a recipe by hand' do
    post link_adm_recipe_import_entry_path(import, ring_entry), params: { recipe_id: stale.id }
    expect(ring_entry.reload).to have_attributes(recipe: stale, match_method: 'manual')
    expect(import.stale_recipes).to be_empty
  end

  describe 'unknown items' do
    it 'lists them with suggestions' do
      get items_adm_recipe_import_path(import)
      expect(response).to have_http_status(200)
      expect(response.body).to include 'Citrine (Unrefined Gemstone)'
      expect(response.body).to include item_path(citrine)
      expect(response.body).to include adm_recipe_import_path(import, item: 'Citrine (Unrefined Gemstone)')
    end

    it 'renames an existing item to the game name' do
      post adm_recipe_import_item_resolutions_path(import),
           params: { name: 'Citrine (Unrefined Gemstone)', resolution: 'rename', item_id: citrine.id }
      expect(citrine.reload.name).to eq 'Citrine (Unrefined Gemstone)'
      expect(ring_entry.reload.problems.join).not_to include 'Citrine'
    end

    it 'aliases by typed item name' do
      post adm_recipe_import_item_resolutions_path(import),
           params: { name: 'Citrine (Unrefined Gemstone)', resolution: 'alias', item_name: 'citrine' }
      expect(citrine.aliases.pluck(:name)).to eq [ 'Citrine (Unrefined Gemstone)' ]
    end

    it 'creates an item' do
      expect {
        post adm_recipe_import_item_resolutions_path(import), params: { name: 'Ring', resolution: 'create' }
      }.to change { Item.find_by_name('Ring').count }.from(0).to(1)
    end

    it 'creates a group and stays on the unknown items' do
      post adm_recipe_import_item_resolutions_path(import),
           params: { name: 'Citrine (Unrefined Gemstone)', resolution: 'create_group' }
      expect(Item.find_by_name('Citrine (Unrefined Gemstone)').first).to be_group
      expect(response).to redirect_to(items_adm_recipe_import_path(import))
      expect(flash[:notice]).to eq 'Created Citrine (Unrefined Gemstone) as a group.'
    end

    it 'creates an archetype' do
      post adm_recipe_import_item_resolutions_path(import), params: { name: 'Ring', resolution: 'create_archetype' }
      expect(Item.find_by_name('Ring').first).to be_archetype
      expect(flash[:notice]).to eq 'Created Ring as an archetype.'
    end

    it 'refuses to make a group of what a game recipe makes' do
      post adm_recipe_import_item_resolutions_path(import), params: { name: 'Ring', resolution: 'create_group' }
      expect(Item.find_by_name('Ring')).to be_empty
      expect(flash[:alert]).to include "the game doesn't make groups"
    end

    it 'creates an "(any)" group for a group slot named like an item, and uses existing items' do
      slots = RecipeImport.create_from_json!(game_export_json(
        game_recipe_hash(name: 'Chair', id: 1, ingredients: { 'Chair' => 1, 'Glue' => 1 },
                         results: { 'Throne' => 1 },
                         keys: { 'Chair' => 'group:3', 'Glue' => item_key('glue') })), user: user)
      get items_adm_recipe_import_path(slots)
      expect(response.body).to include('group slot', 'Create as group Chair (any)')

      post adm_recipe_import_item_resolutions_path(slots),
           params: { name: 'Chair', group_slot: '1', resolution: 'create_group' }
      expect(flash[:notice]).to eq 'Created Chair (any) as a group.'
      expect(Item.find_by_name('Chair (any)').first.game_keys.pluck(:key)).to eq [ 'group:3' ]

      post adm_recipe_import_item_resolutions_path(slots),
           params: { name: 'Glue', resolution: 'use', item_name: 'Citrine' }
      expect(flash[:notice]).to eq "Citrine now has the game's keys for Glue."
      expect(citrine.game_keys.pluck(:key)).to eq [ item_key('glue') ]
    end

    it 'reports problems' do
      post adm_recipe_import_item_resolutions_path(import), params: { name: 'Chair', resolution: 'create' }
      expect(flash[:alert]).to include "isn't an unknown item"
    end
  end

  describe 'stale recipes' do
    let(:import) { RecipeImport.create_from_json!(json, filename: 'export.json', user: user, full_export: true) }

    it 'lists them' do
      get stale_adm_recipe_import_path(import)
      expect(response).to have_http_status(200)
      expect(response.body).to include 'Old Ring'
    end

    it 'lists retired ones' do
      stale.retire!
      get stale_adm_recipe_import_path(import, retired: 1)
      expect(response.body).to include 'Old Ring'
    end

    it 'retires them all' do
      post retire_stale_adm_recipe_import_path(import)
      expect(stale.reload).to be_retired
      expect(outdated.reload).not_to be_retired
    end

    it "won't retire them all when there are implausibly many" do
      stub_const('RecipeImport::STALE_MINIMUM', 0)
      get stale_adm_recipe_import_path(import)
      expect(response.body).to include 'probably not really a full export'
      expect(response.body).not_to include 'Retire all'
      post retire_stale_adm_recipe_import_path(import)
      expect(flash[:alert]).to include 'check this is really a full export'
      expect(stale.reload).not_to be_retired
    end

    it "won't retire anything for a partial export" do
      import.update!(full_export: false)
      post retire_stale_adm_recipe_import_path(import)
      expect(stale.reload).not_to be_retired
    end

    it 'retires and unretires a single recipe' do
      post retire_adm_recipe_path(stale)
      expect(stale.reload).to be_retired
      post unretire_adm_recipe_path(stale)
      expect(stale.reload).not_to be_retired
    end
  end

  describe 'game keys' do
    let(:json) do
      game_export_json(
        game_recipe_hash(name: 'Chair', id: 1, ingredients: { 'Wooden Board' => 2 },
                         keys: { 'Wooden Board' => item_key('board'), 'Chair' => item_key('chair') }),
        groups: [ { key: 'group:7', name: 'Wooden Board', members: { item_key('oak') => 'Oak Board' } } ])
    end

    it 'keeps the export groups' do
      expect(import.game_groups.map(&:key)).to eq [ 'group:7' ]
    end

    it 'previews and records them' do
      get game_keys_adm_recipe_import_path(import)
      expect(response).to have_http_status(200)
      expect(response.body).to include('Record 2 keys', item_key('chair'))

      post record_game_keys_adm_recipe_import_path(import)
      expect(response).to redirect_to(game_keys_adm_recipe_import_path(import))
      expect(flash[:notice]).to eq 'Recorded 2 game keys.'
      expect(chair.game_keys.pluck(:key)).to eq [ item_key('chair') ]
    end

    it 'records an ambiguous key by hand' do
      two = game_export_json(
        game_recipe_hash(name: 'Chair', id: 1, ingredients: { 'Wooden Board' => 1 },
                         keys: { 'Wooden Board' => item_key('b1') }),
        game_recipe_hash(name: 'Bench', id: 2, results: { 'Chair' => 1 }, ingredients: { 'Wooden Board' => 2 },
                         keys: { 'Wooden Board' => item_key('b2') }))
      ambiguous = RecipeImport.create_from_json!(two, user: user)
      get game_keys_adm_recipe_import_path(ambiguous)
      expect(response.body).to include('Name used for several keys (2)')

      post record_game_keys_adm_recipe_import_path(ambiguous), params: { key: item_key('b1') }
      expect(flash[:notice]).to eq "Recorded #{item_key('b1')} for Wooden Board."
      expect(board.game_keys.pluck(:key)).to eq [ item_key('b1') ]
    end

    it 'adopts a name the game changed' do
      board.game_keys.create!(key: item_key('board'), name: 'Wooden Board')
      renamed = RecipeImport.create_from_json!(game_export_json(
        game_recipe_hash(name: 'Chair', id: 1, ingredients: { 'Plank' => 2 }, keys: { 'Plank' => item_key('board') })),
        user: user)
      get game_keys_adm_recipe_import_path(renamed)
      expect(response.body).to include('Renamed in the game (1)')

      post adm_recipe_import_item_resolutions_path(renamed), params: { resolution: 'adopt_alias', key: item_key('board') }
      expect(flash[:notice]).to eq 'Plank is now an alias of Wooden Board.'
      expect(board.aliases.pluck(:name)).to eq [ 'Plank' ]
    end

    it 'says when an export has none' do
      old = RecipeImport.create_from_json!(game_export_json(game_recipe_hash(name: 'Chair')), user: user)
      get game_keys_adm_recipe_import_path(old)
      expect(response.body).to include('This export has no game keys')
    end
  end

  describe 'groups' do
    let!(:group) { create(:item, name: 'Board Group', kind: :group) }
    let(:json) do
      game_export_json(
        game_recipe_hash(name: 'Chair', id: 1, ingredients: { 'Board Group' => 2 }, keys: { 'Board Group' => 'group:7' }),
        groups: [ { key: 'group:7', name: 'Board Group',
                    members: { item_key('board') => 'Wooden Board', item_key('elm') => 'Elm Board' } } ])
    end

    before { group.game_keys.create!(key: 'group:7', name: 'Board Group') }

    it 'lists the groups that differ and adds members' do
      get groups_adm_recipe_import_path(import)
      expect(response).to have_http_status(200)
      expect(response.body).to include('Board Group', 'Create and add (1)', 'Elm Board', 'Add 2 members')

      post add_group_members_adm_recipe_import_path(import), params: { key: 'group:7' }
      expect(flash[:notice]).to eq 'Added 2 members to Board Group.'
      expect(group.members.map(&:name)).to eq [ 'Elm Board', 'Wooden Board' ]

      get groups_adm_recipe_import_path(import, status: 'in_sync')
      expect(response.body).to include('Board Group')
    end

    it 'removes members the game does not list' do
      ItemMembership.create!(group: group, member: chair)
      post remove_group_members_adm_recipe_import_path(import), params: { key: 'group:7' }
      expect(flash[:notice]).to eq 'Removed 1 member from Board Group.'
      expect(group.members).to be_empty
    end

    it 'reports an unknown group' do
      post add_group_members_adm_recipe_import_path(import), params: { key: 'group:99' }
      expect(flash[:alert]).to include "isn't a group in this import"
    end
  end

  describe 'weights' do
    let(:json) do
      game_export_json(game_recipe_hash(name: 'Chair', id: 1, ingredients: { 'Wooden Board' => 2 },
                                        keys: { 'Wooden Board' => item_key('board'), 'Chair' => item_key('chair') },
                                        stats: { 'Chair' => [ { 'key' => 'weight', 'value' => 3.5 } ] }))
    end

    before { chair.game_keys.create!(key: item_key('chair'), name: 'Chair') }

    it 'lists and fills missing weights' do
      get weights_adm_recipe_import_path(import)
      expect(response).to have_http_status(200)
      expect(response.body).to include('Fill 1 missing weight', '3.5')

      post set_weights_adm_recipe_import_path(import), params: { status: 'missing' }
      expect(flash[:notice]).to eq 'Set 1 missing weight.'
      expect(chair.reload.weight).to eq BigDecimal('3.5')
    end

    it 'refuses to set conflicting weights' do
      post set_weights_adm_recipe_import_path(import), params: { status: 'conflict' }
      expect(flash[:alert]).to include "Can't set conflict weights"
    end
  end

  it 'deletes an import' do
    import
    expect { delete adm_recipe_import_path(import) }.to change(RecipeImport, :count).by(-1)
    expect(RecipeImportEntry.count).to eq 0
  end
end
