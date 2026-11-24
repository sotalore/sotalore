require 'rails_helper'

# The public scene pages only show scenes; they're managed in ADM → Scenes
# (spec/requests/adm/scenes_spec.rb).
RSpec.describe "Scenes", type: :request do

  let!(:overworld) { create :scene, :overworld }
  let!(:scene) { create :scene, name: 'West Ravenswood', parent: overworld }
  let(:ai) { User.create_ai_account!(name: 'Companion') }

  before do
    scene.images.attach(io: file_fixture('hawk-on-agave.jpg').open, filename: 'hawk-on-agave.jpg',
                        content_type: 'image/jpeg')
    scene.notes.create!(user: ai, text: 'A locked chest in the ruins.', recorded_at: Time.current, client_id: 'n1')
  end

  { 'signed out' => nil, 'a player' => [], 'an editor' => [ :editor ], 'root' => [ :root ] }.each do |who, traits|
    context "for #{who}" do
      before { sign_in create(:user, *traits) if traits }

      it "lists scenes and shows one, with its gallery, but no controls or notes" do
        get scenes_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('West Ravenswood')
        expect(response.body).not_to include('New Scene', "/scenes/#{scene.id}/edit")

        get scene_path(scene)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Gallery', 'gallery-image')
        expect(response.body).not_to include('data-controller="image-upload"', 'A locked chest', 'Edit')
      end
    end
  end

  it "links root, and only root, to managing scenes in ADM" do
    get scene_path(scene)
    expect(response.body).not_to include(adm_scene_path(scene))

    sign_in create(:user, :editor)
    get scene_path(scene)
    expect(response.body).not_to include(adm_scene_path(scene))

    sign_in create(:user, :root)
    get scene_path(scene)
    expect(response.body).to include(%(href="#{adm_scene_path(scene)}"))
    get scenes_path
    expect(response.body).to include(%(href="#{adm_scenes_path}"))
  end

  it "has no gallery without images" do
    scene.images.purge
    get scene_path(scene)
    expect(response.body).not_to include('Gallery')
  end

  it "sends the old new and edit pages to ADM" do
    get '/scenes/new'
    expect(response).to redirect_to('/adm/scenes/new')
    get "/scenes/#{scene.id}/edit"
    expect(response).to redirect_to("/adm/scenes/#{scene.id}/edit")
  end

  it "no longer changes scenes" do
    sign_in create(:user, :root)
    patch scene_path(scene), params: { scene: { name: 'Renamed' } }
    expect(response).to have_http_status(:not_found)
    delete scene_path(scene)
    expect(response).to have_http_status(:not_found)
    expect(scene.reload.name).to eq 'West Ravenswood'
  end
end
