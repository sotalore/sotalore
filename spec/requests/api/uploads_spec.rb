require 'rails_helper'

RSpec.describe "Api::V1 uploads", type: :request do
  let(:admin) { create(:user, :root) }
  let(:ai)    { User.create_ai_account!(name: 'Companion') }

  def headers(scopes = %w[ upload ])
    { 'Authorization' => "Bearer #{ApiToken.issue!(user: ai, name: 't', scopes: scopes, created_by: admin).last}" }
  end

  def example(name)
    Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/plugin-examples', name), 'application/json')
  end

  def upload_json(json, name = 'upload.json')
    Rack::Test::UploadedFile.new(StringIO.new(json), 'application/json', original_filename: name)
  end

  it 'uploads a recipe export as an import for an admin to review, as the token account' do
    post api_v1_recipe_imports_path, params: { file: example('sotalore-recipes-one.json') }, headers: headers
    expect(response).to have_http_status(:created)
    body = response.parsed_body
    import = RecipeImport.find(body['id'])
    expect(body).to include('filename' => 'sotalore-recipes-one.json', 'entries' => 1, 'scope' => 'one',
                            'review_url' => adm_recipe_import_url(import))
    expect(import.uploaded_by).to eq ai
  end

  it 'uploads an item catalog and a finds file' do
    auth = headers
    post api_v1_item_catalog_imports_path, params: { file: example('sotalore-item-catalog.json') }, headers: auth
    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include('items' => ItemCatalogImport.sole.catalog.entries.size,
                                            'review_url' => adm_item_catalog_import_url(ItemCatalogImport.sole))

    post api_v1_finds_imports_path, params: { file: example('sotalore-scene-finds.json') }, headers: auth
    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include('scenes' => FindsImport.sole.finds.scenes.size)
    expect(FindsImport.sole.uploaded_by).to eq ai
  end

  it 'returns the import already made when the same file comes again' do
    auth = headers
    post api_v1_finds_imports_path, params: { file: example('sotalore-scene-finds.json') }, headers: auth
    first = response.parsed_body['id']

    post api_v1_finds_imports_path, params: { file: example('sotalore-scene-finds.json') }, headers: auth
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['id']).to eq first
    expect(FindsImport.count).to eq 1
  end

  it 'refuses a file sent to the wrong endpoint, or with no type' do
    auth = headers
    post api_v1_item_catalog_imports_path, params: { file: example('sotalore-scene-finds.json') }, headers: auth
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body['error']).to include 'send it to POST /api/v1/finds_imports'

    untyped = JSON.parse(File.read(Rails.root.join('spec/fixtures/plugin-examples/sotalore-scene-finds.json')))
                  .except('type').to_json
    post api_v1_finds_imports_path, params: { file: upload_json(untyped) }, headers: auth
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body['error']).to include 'no "type"'

    post api_v1_finds_imports_path, params: { file: upload_json('not json') }, headers: auth
    expect(response).to have_http_status(:unprocessable_content)
    expect(FindsImport.count).to eq 0
  end

  it 'needs a file' do
    post api_v1_recipe_imports_path, params: { file: 'oops' }, headers: headers
    expect(response).to have_http_status(:bad_request)
  end

  it 'needs the upload scope' do
    post api_v1_recipe_imports_path, params: { file: example('sotalore-recipes-one.json') },
                                     headers: headers(%w[ read propose ])
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body['error']).to include 'upload scope'
    expect(RecipeImport.count).to eq 0
  end

  it 'still needs the read scope to read imports' do
    get api_v1_recipe_imports_path, headers: headers
    expect(response).to have_http_status(:forbidden)
  end
end
