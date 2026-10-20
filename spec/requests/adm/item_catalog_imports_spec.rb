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
    expect(flash[:notice]).to eq 'Applied: 1 game key recorded, 1 weight filled, 0 tools set, 2 salvage results added, and 0 updated.'
    expect(backpack.reload.weight).to eq 2
    expect(backpack.item_salvages_as_source.map { _1.salvage_to.name }).to contain_exactly('Leather Scrap', 'Strap')

    get item_path(backpack)
    expect(response.body).to include('(1–15, 100%)')
    get adm_item_catalog_imports_path
    expect(response.body).to include('sotalore-items.json')
  end

  it 'creates many unknown items at once, keeping their list open' do
    import = upload(catalog_json(catalog_entry(name: 'Odd Note', key: item_key('note')), catalog_entry(name: 'Quest Key'),
                                 catalog_entry(name: 'Backpack')))
    get adm_item_catalog_import_path(import)
    expect(response.body).to include('Create selected', 'Select all')

    selected = [ { name: 'Odd Note', key: item_key('note') }, { name: 'Quest Key', key: item_key('Quest Key') } ]
    post resolve_adm_item_catalog_import_path(import),
         params: { resolution: 'create_many', open: 'catalog', selected: selected.map(&:to_json) }
    expect(response).to redirect_to(adm_item_catalog_import_path(import, open: 'catalog'))
    expect(flash[:notice]).to eq 'Created 2 items.'
    expect(Item.find_by_name('Odd Note').sole.game_keys.pluck(:key)).to eq [ item_key('note') ]

    post resolve_adm_item_catalog_import_path(import), params: { resolution: 'create_many', selected: [ selected.first.to_json ] }
    expect(flash[:alert]).to include "Couldn't create Odd Note"
  end

  it 'lists unknown catalog items open when asked, and crafted ones left out as a list' do
    import = upload(catalog_json(catalog_entry(name: 'Odd Note'),
                                 catalog_entry(name: 'Iron Sword +12', key: item_key('sword'), crafted: true)))
    get adm_item_catalog_import_path(import, open: 'catalog')
    expect(response.body).to match(/<details[^>]*open[^>]*>\s*<summary[^>]*>Catalog items/)
    expect(response.body).to include('<li>Iron Sword +12</li>')
  end

  it 'updates weights that differ on request' do
    scrap.update!(weight: 0.1)
    import = upload(catalog_json(catalog_entry(name: 'Leather Scrap', weight: 0.05)))
    get adm_item_catalog_import_path(import)
    expect(response.body).to include('Update 1 different weight')
    post update_weights_adm_item_catalog_import_path(import)
    expect(flash[:notice]).to eq "Updated 1 weight to the game's."
    expect(scrap.reload.weight).to eq BigDecimal('0.05')
    expect(scrap.comments.revision.count).to eq 1
  end

  it 'lists, shows and deletes an import from an older plugin, but won\'t apply it' do
    old = ItemCatalogImport.create!(filename: 'old.json', uploaded_by: admin,
                                    payload: JSON.parse(catalog_json(catalog_entry(name: 'Backpack', weight: 99),
                                                                     plugin_version: '0.7.3')))
    get adm_item_catalog_imports_path
    expect(response).to have_http_status(200)
    expect(response.body).to include('too old to apply')

    get adm_item_catalog_import_path(old)
    expect(response).to have_http_status(200)
    expect(response.body).to include("can't be applied", 'Delete this import')
    expect(response.body).not_to include('>Apply<')

    post apply_adm_item_catalog_import_path(old)
    expect(flash[:alert]).to include 'from a plugin before 0.8.1'
    expect(backpack.reload.weight).to be_nil

    delete adm_item_catalog_import_path(old)
    expect(ItemCatalogImport.exists?(old.id)).to be false
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
