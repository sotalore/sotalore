require 'rails_helper'

RSpec.describe "API collections", type: :request do
  let(:admin) { create(:user, :root) }
  let(:ai)    { User.create_ai_account!(name: 'Claude') }
  let(:auth)  { { 'Authorization' => "Bearer #{ApiToken.issue!(user: ai, name: 't', scopes: %w[ read propose ], created_by: admin).last}" } }

  let!(:armor) { Collection.create!(name: 'Armor', description: 'Worn.') }
  let!(:light) { Collection.create!(name: 'Light Armor').tap { CollectionLink.create!(parent: armor, child: _1) } }
  let!(:boots) { create(:item, name: 'Fortified Leather Boots', kind: :archetype, use: :armor) }
  let!(:helm)  { create(:item, name: 'Leather Helm', use: :armor, effects: '+2% Magic Fizzle Chance') }

  before do
    light.collection_items.create!(item: boots)
    helm.game_keys.create!(key: item_key('helm'), name: 'Leather Helm',
                           catalog: { 'details' => { 'types' => [ 'Leather Light Armor (Head)' ] } })
  end

  def get_json(path, **params)
    get path, params: params, headers: auth
    expect(response).to have_http_status(:ok)
    response.parsed_body
  end

  it 'lists every collection with how they nest' do
    found = get_json(api_v1_collections_path)['collections']
    expect(found.map { _1['name'] }).to eq [ 'Armor', 'Light Armor' ]
    expect(found.first).to include('description' => 'Worn.', 'children' => [ { 'id' => light.id, 'name' => 'Light Armor' } ], 'items' => 0)
    expect(found.last['parents']).to eq [ { 'id' => armor.id, 'name' => 'Armor' } ]
  end

  it 'shows what a collection holds, counting those inside it' do
    body = get_json(api_v1_collection_path(armor))
    expect(body['items']).to eq []
    expect(body['all_items']).to eq [ { 'id' => boots.id, 'name' => boots.name, 'kind' => 'archetype', 'use' => 'armor',
                                        'listed_in' => [ { 'id' => light.id, 'name' => 'Light Armor' } ] } ]
  end

  it "shows an item's collections, tooltip types and effects, and finds items by use" do
    expect(get_json(api_v1_item_path(boots))['collections']).to eq [ { 'id' => light.id, 'name' => 'Light Armor' } ]
    expect(get_json(api_v1_item_path(helm))).to include('tooltip_types' => [ 'Leather Light Armor (Head)' ],
                                                        'effects' => '+2% Magic Fizzle Chance',
                                                        'game_effects' => [], 'crafting_bonus' => [])
    create(:item, name: 'Wax')
    expect(get_json(api_v1_items_path, use: 'armor')['items'].map { _1['name'] }).to eq [ boots.name, helm.name ]
  end

  it 'proposes a collection with lists of ids' do
    post api_v1_proposals_path, headers: auth, as: :json,
         params: { change: 'collection.create', reason: 'A set of six', evidence: 'Named alike',
                   params: { name: 'Fortified Leather Armor', parent_ids: [ light.id ], item_ids: [ boots.id ] } }
    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include('summary' => 'Make collection Fortified Leather Armor',
                                            'params' => include('item_ids' => [ boots.id ]))

    post api_v1_proposals_path, headers: auth, as: :json,
         params: { change: 'collection.add_items', subject_id: light.id, reason: 'x', params: { item_ids: [ helm.id ] } }
    expect(response.parsed_body['subject']).to include('type' => 'Collection', 'name' => 'Light Armor')
  end
end
