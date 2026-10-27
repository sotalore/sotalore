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
      expect(response).to redirect_to(adm_finds_import_path(import, open: 'items'))
      expect(flash[:notice]).to eq 'Created 1 item.'
      expect(Item.find_by_name('Wolf Pelt')).to exist

      post resolve_adm_finds_import_path(import), params: { resolution: 'create_many', open: 'items' }
      expect(flash[:alert]).to eq 'Select the items to create.'
    end

    # Replace visits, so Turbo takes the redirect back (with ?open=) as a
    # refresh of the same page, and morphs it.
    it 'resolves through Turbo, as a refresh of the review page' do
      import = upload
      get adm_finds_import_path(import)
      expect(response.body).to include('data-turbo-action="replace"')
      expect(response.body).not_to include('data-turbo="false"')
    end

    it 'reviews what was targeted but never fought, adding or ignoring each' do
      json = finds_json(finds_scene_hash(scene: 'Kingsroad', seen: { 'Large Stag' => [ 30, 30 ], 'Fighter' => [] }))
      file = Rack::Test::UploadedFile.new(StringIO.new(json), 'application/json', original_filename: 'sotalore-scene-finds.json')
      post adm_finds_imports_path, params: { file: file }
      import = FindsImport.last
      get adm_finds_import_path(import)
      expect(response.body).to include('Targeted, never fought (2)', 'Large Stag', 'Fighter')

      post resolve_adm_finds_import_path(import),
           params: { resolution: 'creature', scene_id: kingsroad.id, name: 'Large Stag', open: 'seen' }
      expect(response).to redirect_to(adm_finds_import_path(import, open: 'seen'))
      expect(flash[:notice]).to eq 'Large Stag now lives in Kingsroad.'
      expect(kingsroad.creatures.map(&:name)).to eq [ 'Large Stag' ]

      post resolve_adm_finds_import_path(import), params: { resolution: 'ignore', scene_id: kingsroad.id, name: 'Fighter' }
      expect(flash[:notice]).to eq 'Ignoring Fighter in Kingsroad.'
      get adm_finds_import_path(import)
      expect(response.body).not_to include('Targeted, never fought (')
      expect(response.body).to include('Fighter (ignored here)')

      post resolve_adm_finds_import_path(import), params: { resolution: 'ignore', scene_id: kingsroad.id, name: 'Fighter' }
      expect(flash[:alert]).to include "isn't waiting for review"
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

    it 'sets the skill that gathers from a node' do
      node = GatheringNode.create!(name: 'Copper Vein')
      get gathering_nodes_path
      expect(response.body).to include('Copper Vein', 'skill not set')
      get edit_gathering_node_path(node)
      expect(response.body).to include('Mining', 'Forestry')
      expect(response.body).not_to include('Field Dressing')
      patch gathering_node_path(node), params: { gathering_node: { gathering_skill: 'mining', notes: '' } }
      expect(response).to redirect_to(gathering_node_path(node))
      expect(node.reload.gathering_skill).to eq CraftSkill.find('mining')
      get gathering_node_path(node)
      expect(response.body).to include('Gathered by', 'Mining')

      patch gathering_node_path(node), params: { gathering_node: { gathering_skill: 'field_dressing' } }
      expect(response).to have_http_status(:unprocessable_content)
      patch gathering_node_path(node), params: { gathering_node: { gathering_skill: '' } }
      expect(node.reload.gathering_skill).to be_nil
    end

    it 'moves a creature recorded as a node to the creatures' do
      node = GatheringNode.create!(name: 'Grizzly Bear')
      HarvestYield.create!(source: node, item: hide)
      get gathering_node_path(node)
      expect(response.body).to include('Move to creatures')
      post move_to_creatures_gathering_node_path(node)
      bear = Creature.find_by!(name: 'Grizzly Bear')
      expect(response).to redirect_to(creature_path(bear))
      expect(flash[:notice]).to eq 'Moved Grizzly Bear to the creatures.'
      expect(bear.yields).to eq [ hide ]
    end

    it 'shows nobody else, yet' do
      sign_in create(:user, :editor)
      get item_path(hide)
      expect(response.body).not_to include('Where to Find It')
      get scene_path(kingsroad)
      expect(response.body).not_to include('Found Here')
      get creatures_path
      expect(response).to redirect_to(root_path)
      node = GatheringNode.create!(name: 'Copper Vein')
      patch gathering_node_path(node), params: { gathering_node: { gathering_skill: 'mining' } }
      expect(node.reload.gathering_skill).to be_nil
      post move_to_creatures_gathering_node_path(node)
      expect(GatheringNode.exists?(node.id)).to be true
    end
  end

  it 'keeps finds imports to root' do
    sign_in create(:user, :editor)
    get adm_finds_imports_path
    expect(response).to redirect_to(root_path)
  end
end
