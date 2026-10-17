require 'rails_helper'

RSpec.describe "Adm::ItemCatalogImports", type: :request do
  let(:admin) { create(:user, :root) }
  let!(:backpack) { create(:item, name: 'Backpack') }
  let!(:scrap)    { create(:item, name: 'Leather Scrap') }
  before { sign_in admin }

  def upload(json)
    file = Rack::Test::UploadedFile.new(StringIO.new(json), 'application/json', original_filename: 'sotalore-items.json')
    post adm_item_catalog_imports_path, params: { file: file }
    ItemCatalogImport.last
  end

  it 'uploads, reviews, resolves and applies' do
    import = upload(catalog_json(
      catalog_entry(name: 'Backpack', weight: 2, salvage: { 'Leather Scrap' => [ 1, 15, 100 ], 'Strap' => [ 1, 1, 5 ] }),
      catalog_entry(name: 'Odd Note')))
    expect(response).to redirect_to(adm_item_catalog_import_path(import))

    get adm_item_catalog_import_path(import)
    expect(response).to have_http_status(200)
    expect(response.body).to include('Backpack', 'Leather Scrap 1–15 100%', 'Strap', 'Odd Note')

    post resolve_adm_item_catalog_import_path(import), params: { resolution: 'create', name: 'Strap' }
    expect(flash[:notice]).to eq 'Created Strap.'
    post apply_adm_item_catalog_import_path(import)
    expect(flash[:notice]).to eq 'Applied: 1 game key recorded, 0 tools set, 2 salvage results added, and 0 updated.'
    expect(backpack.reload.weight).to be_nil
    expect(backpack.item_salvages_as_source.map { _1.salvage_to.name }).to contain_exactly('Leather Scrap', 'Strap')

    get item_path(backpack)
    expect(response.body).to include('(1–15, 100%)')
    get adm_item_catalog_imports_path
    expect(response.body).to include('sotalore-items.json')
  end

  it 'rejects other files' do
    upload('{"scenes": []}')
    expect(flash[:alert]).to include "Couldn't import"
  end

  it 'is only for root' do
    sign_in create(:user, :editor)
    get adm_item_catalog_imports_path
    expect(response).to redirect_to(root_path)
  end
end
