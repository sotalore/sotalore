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

  def upload(content)
    file = Rack::Test::UploadedFile.new(StringIO.new(content), 'application/json',
                                        original_filename: 'export.json')
    post adm_recipe_imports_path, params: { file: file }
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

    it 'reports problems' do
      post adm_recipe_import_item_resolutions_path(import), params: { name: 'Chair', resolution: 'create' }
      expect(flash[:alert]).to include 'already a known item'
    end
  end

  describe 'stale recipes' do
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

    it 'retires and unretires a single recipe' do
      post retire_adm_recipe_path(stale)
      expect(stale.reload).to be_retired
      post unretire_adm_recipe_path(stale)
      expect(stale.reload).not_to be_retired
    end
  end

  it 'deletes an import' do
    import
    expect { delete adm_recipe_import_path(import) }.to change(RecipeImport, :count).by(-1)
    expect(RecipeImportEntry.count).to eq 0
  end
end
