require 'rails_helper'

RSpec.describe "Api::V1 scenes and their images", type: :request do
  let(:admin) { create(:user, :root) }
  let(:ai)    { User.create_ai_account!(name: 'Companion') }
  let!(:ravenswood) { create(:scene, name: 'West Ravenswood', game_name: 'HiddenVale_Forest02_Tier2') }
  let!(:valeway)    { create(:scene, name: 'South Valeway') }

  def headers(scopes = %w[ read images ])
    { 'Authorization' => "Bearer #{ApiToken.issue!(user: ai, name: 't', scopes: scopes, created_by: admin).last}" }
  end

  def jpeg
    fixture_file_upload('hawk-on-agave.jpg', 'image/jpeg')
  end

  def upload(bytes, name, type = 'application/octet-stream')
    Rack::Test::UploadedFile.new(StringIO.new(bytes), type, original_filename: name)
  end

  describe 'GET /scenes' do
    it 'finds a scene by the game name, the site name, or part of it' do
      auth = headers
      get api_v1_scenes_path, params: { game_name: 'HiddenVale_Forest02_Tier2' }, headers: auth
      expect(response.parsed_body['scenes'].sole).to include(
        'id' => ravenswood.id, 'name' => 'West Ravenswood', 'game_name' => 'HiddenVale_Forest02_Tier2',
        'region' => ravenswood.region, 'level' => ravenswood.level, 'images' => 0,
        'parent' => include('name' => 'Overworld'), 'url' => scene_url(ravenswood)
      )

      get api_v1_scenes_path, params: { name: 'south valeway' }, headers: auth
      expect(response.parsed_body['scenes'].map { _1['id'] }).to eq [ valeway.id ]

      get api_v1_scenes_path, params: { q: 'raven' }, headers: auth
      expect(response.parsed_body['scenes'].map { _1['id'] }).to eq [ ravenswood.id ]

      get api_v1_scenes_path, params: { game_name: 'Nowhere_Tier9' }, headers: auth
      expect(response.parsed_body['scenes']).to eq []
    end
  end

  describe 'POST /scenes/:id/images' do
    it 'adds the image to the gallery at once, recording who sent it' do
      post api_v1_scene_images_path(ravenswood), params: { file: jpeg, taken_at: '2026-11-23T10:15:00-08:00' },
                                                 headers: headers
      expect(response).to have_http_status(:created)
      image = ravenswood.images.sole
      expect(response.parsed_body).to include(
        'id' => image.id, 'scene' => include('id' => ravenswood.id, 'url' => scene_url(ravenswood)),
        'content_type' => 'image/jpeg', 'byte_size' => image.blob.byte_size, 'url' => rails_blob_url(image)
      )
      expect(response.parsed_body['preview_url']).to be_present
      expect(image.blob.metadata['custom']).to eq('uploaded_by_id' => ai.id, 'taken_at' => '2026-11-23T10:15:00-08:00')
    end

    it 'takes PNG and WebP, by what the bytes are, not the name' do
      auth = headers
      png = Vips::Image.black(4, 4).write_to_buffer('.png')
      post api_v1_scene_images_path(ravenswood), params: { file: upload(png, 'shot.jpg') }, headers: auth
      expect(response.parsed_body['content_type']).to eq 'image/png'

      webp = Vips::Image.black(5, 5).write_to_buffer('.webp')
      post api_v1_scene_images_path(ravenswood), params: { file: upload(webp, 'shot.webp') }, headers: auth
      expect(response).to have_http_status(:created)
      expect(ravenswood.images.count).to eq 2
    end

    it 'returns the image already there when the same file comes again' do
      auth = headers
      post api_v1_scene_images_path(ravenswood), params: { file: jpeg }, headers: auth
      first = response.parsed_body['id']

      post api_v1_scene_images_path(ravenswood), params: { file: jpeg }, headers: auth
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq first
      expect(ravenswood.images.count).to eq 1

      post api_v1_scene_images_path(valeway), params: { file: jpeg }, headers: auth
      expect(response).to have_http_status(:created)
    end

    it 'refuses what is not a PNG, JPEG or WebP image, a bad time, or no file' do
      auth = headers
      post api_v1_scene_images_path(ravenswood), params: { file: upload('GIF89a fake', 'x.png', 'image/png') },
                                                 headers: auth
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['error']).to include 'PNG, JPEG or WebP'

      post api_v1_scene_images_path(ravenswood), params: { file: jpeg, taken_at: 'yesterday' }, headers: auth
      expect(response).to have_http_status(:unprocessable_content)

      post api_v1_scene_images_path(ravenswood), params: { file: 'oops' }, headers: auth
      expect(response).to have_http_status(:bad_request)

      post api_v1_scene_images_path(0), params: { file: jpeg }, headers: auth
      expect(response).to have_http_status(:not_found)
      expect(ActiveStorage::Attachment.count).to eq 0
    end

    it 'needs the images scope' do
      post api_v1_scene_images_path(ravenswood), params: { file: jpeg }, headers: headers(%w[ read upload ])
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body['error']).to include 'images scope'
      expect(ravenswood.images).to be_empty
    end
  end
end
