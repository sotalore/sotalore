require 'rails_helper'

RSpec.describe "Read-only API", type: :request do
  let(:admin) { create(:user, :root) }
  let(:ai)    { User.create_ai_account!(name: 'Claude') }
  let(:auth)  { { 'Authorization' => "Bearer #{ApiToken.issue!(user: ai, name: 't', scopes: %w[ read ], created_by: admin).last}" } }

  let!(:board)   { create(:item, name: 'Wooden Board', weight: 1.5) }
  let!(:boards)  { create(:item, name: 'Board Group', kind: :group) }
  let!(:chair)   { create(:item, name: 'Chair') }
  let!(:synced)  { create(:recipe, name: 'Chair', craft_skill: 'carpentry', with_ingredients: { board => 2 }, with_results: { chair => 1 }) }
  let!(:old)     { create(:recipe, name: 'Chair', craft_skill: 'carpentry', with_ingredients: { boards => 3 }, with_results: { chair => 1 }) }

  before do
    ItemMembership.create!(group: boards, member: board)
    board.game_keys.create!(key: item_key('board'), name: 'Wooden Board')
    synced.update_columns(game_id: 1, game_synced_at: Time.current)
  end

  def get_json(path, **params)
    get path, params: params, headers: auth
    expect(response).to have_http_status(:ok)
    response.parsed_body
  end

  it 'needs a token with the read scope' do
    get api_v1_items_path
    expect(response).to have_http_status(:unauthorized)
    propose_only = ApiToken.issue!(user: ai, name: 'p', scopes: %w[ propose ], created_by: admin).last
    get api_v1_items_path, headers: { 'Authorization' => "Bearer #{propose_only}" }
    expect(response).to have_http_status(:forbidden)
  end

  describe 'items' do
    it 'searches by name and kind, a page at a time' do
      body = get_json(api_v1_items_path, q: 'board')
      expect(body['items'].map { _1['name'] }).to eq [ 'Board Group', 'Wooden Board' ]
      expect(body['page']).to include('total_count' => 2, 'number' => 1)
      expect(get_json(api_v1_items_path, kind: 'group')['items'].map { _1['name'] }).to eq [ 'Board Group' ]
      expect(get_json(api_v1_items_path, per: 1, page: 2)['items'].size).to eq 1
    end

    it 'shows everything about an item' do
      body = get_json(api_v1_item_path(board))
      expect(body).to include('name' => 'Wooden Board', 'weight' => '1.5', 'kind' => 'concrete',
                              'game_keys' => [ { 'key' => item_key('board'), 'name' => 'Wooden Board' } ])
      expect(body['member_of'].map { _1['name'] }).to eq [ 'Board Group' ]
      expect(body['ingredient_of_recipes'].map { _1['id'] }).to eq [ synced.id ]
      expect(get_json(api_v1_item_path(boards))['members'].map { _1['name'] }).to eq [ 'Wooden Board' ]
    end
  end

  describe 'recipes' do
    it 'lists them, filtered by whether the game has them' do
      body = get_json(api_v1_recipes_path, synced: 'false')
      expect(body['recipes'].map { _1['id'] }).to eq [ old.id ]
      expect(body['recipes'].first).to include('kind' => 'concrete', 'game_id' => nil,
                                               'ingredients' => [ { 'item' => include('name' => 'Board Group'), 'count' => 3 } ])
      old.retire!
      expect(get_json(api_v1_recipes_path)['recipes'].map { _1['id'] }).to eq [ synced.id ]
      expect(get_json(api_v1_recipes_path, status: 'retired')['recipes'].map { _1['id'] }).to eq [ old.id ]
      expect(get_json(api_v1_recipes_path, status: 'all', craft_skill: 'tailoring')['recipes']).to be_empty
    end

    it 'shows what helps decide whether one belongs' do
      import = RecipeImport.create_from_json!(game_export_json(
        game_recipe_hash(name: 'Chair', id: 1, ingredients: { 'Wooden Board' => 2 })), user: admin)
      import.update_columns(full_export: true)
      body = get_json(api_v1_recipe_path(old))
      expect(body).to include('saved_by_users' => 0, 'game_id' => nil)
      expect(body['same_name_recipes'].map { _1['id'] }).to eq [ synced.id ]
      expect(body['latest_full_import']).to include('id' => import.id, 'entry' => nil)
      expect(get_json(api_v1_recipe_path(synced))['latest_full_import']['entry']).to include('match_method' => 'game_id')
    end
  end

  describe 'recipe imports' do
    let!(:import) do
      RecipeImport.create_from_json!(game_export_json(
        game_recipe_hash(name: 'Chair', id: 1, ingredients: { 'Wooden Board' => 2 }),
        game_recipe_hash(name: 'Ring', id: 2, ingredients: { 'Gold' => 1 })), user: admin)
    end

    it 'lists imports and their entries' do
      expect(get_json(api_v1_recipe_imports_path)['recipe_imports'].first)
        .to include('id' => import.id, 'entries' => 2, 'statuses' => include('outdated' => 1, 'blocked' => 1))
      expect(get_json(api_v1_recipe_import_path('latest'))).to include('id' => import.id, 'unknown_items' => 2)
      body = get_json(entries_api_v1_recipe_import_path(import), status: 'blocked')
      expect(body['entries'].sole).to include('name' => 'Ring', 'problems' => include(/Unknown items/))
    end

    it 'lists the stale recipes of a full export' do
      body = get_json(stale_api_v1_recipe_import_path(import))
      expect(body['recipes'].map { _1['id'] }).to eq [ old.id ]
    end
  end

  it 'lists the item review' do
    body = get_json(api_v1_item_reviews_path, filter: 'group')
    expect(body['filter']).to eq 'group'
    expect(body['items'].sole).to include('name' => 'Board Group', 'members' => 1)
  end
end
