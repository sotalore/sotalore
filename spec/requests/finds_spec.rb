require 'rails_helper'

RSpec.describe 'Finds', type: :request do
  let(:admin) { create(:user, :root) }
  let!(:kingsroad) { create(:scene, name: 'Kingsroad') }
  let!(:hide) { create(:item, name: 'Animal Hide') }
  let(:json) do
    finds_json(finds_scene_hash(scene: 'Kingsroad', items: { 'Animal Hide' => nil, 'Wolf Pelt' => nil },
                                creatures: { 'Rabbit' => [ 2, 3 ] }, nodes: { 'Rabbit' => [ 'Animal Hide' ], 'Pine Tree' => [] }))
  end

  def upload
    file = Rack::Test::UploadedFile.new(StringIO.new(json), 'application/json', original_filename: 'sotalore-finds.json')
    post adm_finds_imports_path, params: { file: file }
    FindsImport.last
  end

  describe 'importing' do
    before { sign_in admin }

    it 'uploads, reviews, resolves and applies' do
      import = upload
      expect(response).to redirect_to(adm_finds_import_path(import))
      get adm_finds_import_path(import)
      expect(response).to have_http_status(200)
      expect(response.body).to include('Kingsroad', 'know (1)', 'Wolf Pelt', 'Field dressing Rabbit')

      post resolve_adm_finds_import_path(import), params: { resolution: 'create', name: 'Wolf Pelt' }
      expect(flash[:notice]).to eq 'Created Wolf Pelt.'
      post apply_adm_finds_import_path(import)
      expect(flash[:notice]).to eq 'Applied. New: 2 items, 1 creature, 1 node, 1 yield.'

      get adm_finds_imports_path
      expect(response.body).to include('sotalore-finds.json')
    end

    it 'creates many unknown items at once, coming back at the list' do
      import = upload
      get adm_finds_import_path(import)
      expect(response.body).to include('Create selected', 'Select all')
      post resolve_adm_finds_import_path(import),
           params: { resolution: 'create_many', open: 'items', selected: [ { name: 'Wolf Pelt', key: nil }.to_json ] }
      expect(response).to redirect_to(adm_finds_import_path(import, open: 'items', anchor: 'items'))
      expect(flash[:notice]).to eq 'Created 1 item.'
      expect(Item.find_by_name('Wolf Pelt')).to exist

      post resolve_adm_finds_import_path(import), params: { resolution: 'create_many', open: 'items' }
      expect(flash[:alert]).to eq 'Select the items to create.'
    end

    it 'rejects other files' do
      file = Rack::Test::UploadedFile.new(StringIO.new('{"recipes": []}'), 'application/json', original_filename: 'x.json')
      post adm_finds_imports_path, params: { file: file }
      expect(flash[:alert]).to include "Couldn't import"
    end
  end

  describe 'showing finds' do
    before do
      sign_in admin
      upload.apply!
    end

    it 'shows admins where things are found' do
      get item_path(hide)
      expect(response.body).to include('Where to Find It', 'Found in 1 scene', 'Field dressing gives it from')
      get scene_path(kingsroad)
      expect(response.body).to include('Found Here', 'Rabbit', '(2–3)', 'only here', 'Pine Tree')
      rabbit = Creature.find_by!(name: 'Rabbit')
      get creature_path(rabbit)
      expect(response.body).to include('Lives in', 'Kingsroad', 'Field dressing gives', 'Animal Hide')
      get creatures_path
      expect(response.body).to include('Rabbit')
      get gathering_node_path(GatheringNode.find_by!(name: 'Pine Tree'))
      expect(response.body).to include('Harvesting gives', 'nothing recorded yet')
    end

    it 'shows nobody else, yet' do
      sign_in create(:user, :editor)
      get item_path(hide)
      expect(response.body).not_to include('Where to Find It')
      get scene_path(kingsroad)
      expect(response.body).not_to include('Found Here')
      get creatures_path
      expect(response).to redirect_to(root_path)
    end
  end

  it 'keeps finds imports to root' do
    sign_in create(:user, :editor)
    get adm_finds_imports_path
    expect(response).to redirect_to(root_path)
  end
end
