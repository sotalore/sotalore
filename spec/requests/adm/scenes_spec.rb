require 'rails_helper'

RSpec.describe 'Adm::Scenes', type: :request do
  let(:admin) { create(:user, :root) }
  let!(:world)    { create(:scene, name: 'Overworld', region_id: nil) }
  let!(:road)     { create(:scene, name: 'Kingsroad', level_id: 1, region_id: 1, finds_imported_at: 2.days.ago) }
  let!(:forest)   { create(:scene, name: 'Spectral Forest', level_id: 4, region_id: 1) }
  let!(:outskirts) { create(:scene, name: 'Solace Outskirts', level_id: 0, region_id: 1) }
  let!(:far)      { create(:scene, name: 'Far Away', level_id: 2, region_id: 2) }
  before { sign_in admin }

  def names
    response.body.scan(%r{<a href="/adm/scenes/\d+" class="Link Link--primary">([^<]+)</a>}).flatten
  end

  it 'lists scenes without finds, lowest tier first, leaving out the whole map' do
    get adm_scenes_path
    expect(response).to have_http_status(200)
    expect(names).to eq [ 'Solace Outskirts', 'Far Away', 'Spectral Forest' ]
    expect(response.body).to include('1 of 4 scenes have finds imported', %(href="#{new_adm_scene_path}"))
  end

  it 'filters by region and status, and sorts' do
    get adm_scenes_path(region: 1, status: 'all', sort: 'name')
    expect(names).to eq [ 'Kingsroad', 'Solace Outskirts', 'Spectral Forest' ]
    expect(response.body).to include('1 of 3 scenes')

    get adm_scenes_path(status: 'imported')
    expect(names).to eq [ 'Kingsroad' ]
  end

  it 'counts what each scene has' do
    SceneFind.create!(scene: road, item: create(:item))
    SceneFind.create!(scene: road, item: create(:item))
    SceneCreature.create!(scene: road, creature: Creature.create!(name: 'Rabbit'))
    get adm_scenes_path(status: 'imported')
    expect(response.body).to match(%r{<td class="pr-3 text-right">2</td><td class="pr-3 text-right">1</td><td class="pr-3 text-right"></td>})
  end

  it 'counts images and notes, and finds scenes by name whether or not their finds are imported' do
    road.images.attach(io: file_fixture('hawk-on-agave.jpg').open, filename: 'hawk.jpg', content_type: 'image/jpeg')
    2.times { road.notes.create!(user: ai, text: 'x', recorded_at: Time.current, client_id: "n#{_1}") }
    get adm_scenes_path(q: 'kings')
    expect(names).to eq [ 'Kingsroad' ]
    expect(response.body).to match(%r{<td class="pr-3 text-right">1</td><td class="text-right">2</td>})
  end

  let(:ai) { User.create_ai_account!(name: 'Companion') }

  describe "a scene's page" do
    it 'shows its details, finds, gallery and notes' do
      road.update!(game_name: 'Kingsroad_Tier1', parent: world)
      road.images.attach(io: file_fixture('hawk-on-agave.jpg').open, filename: 'hawk.jpg', content_type: 'image/jpeg',
                         metadata: { custom: { 'uploaded_by_id' => ai.id.to_s } })
      road.notes.create!(user: ai, text: 'A locked chest in the ruins.', recorded_at: Time.current, duration: 75,
                         client_id: 'n1')
      get adm_scene_path(road)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Kingsroad_Tier1', 'Last imported', 'Gallery (1)', 'by Companion',
                                       'data-controller="image-upload"', 'Notes (1)', 'A locked chest in the ruins.',
                                       '1:15 long', %(href="#{scene_path(road)}"))
    end

    it 'adds and deletes images' do
      post adm_scene_images_path(road), params: { scene: { images: [ fixture_file_upload('hawk-on-agave.jpg', 'image/jpeg') ] } }
      expect(response).to redirect_to(adm_scene_path(road))
      image = road.images.sole

      delete adm_scene_image_path(road, image)
      expect(response).to redirect_to(adm_scene_path(road))
      expect(road.reload.images).to be_empty
    end

    it 'deletes a note' do
      note = road.notes.create!(user: ai, text: 'x', recorded_at: Time.current, client_id: 'n1')
      delete adm_scene_note_path(road, note)
      expect(response).to redirect_to(adm_scene_path(road))
      expect(road.notes.reload).to be_empty
    end
  end

  describe 'adding and editing' do
    it 'adds a scene' do
      get new_adm_scene_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(action="#{adm_scenes_path}"))

      post adm_scenes_path, params: { scene: { name: 'Ardoris', parent_id: world.id, level_id: 2 } }
      scene = Scene.find_by!(name: 'Ardoris')
      expect(response).to redirect_to(adm_scene_path(scene))

      post adm_scenes_path, params: { scene: { name: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'edits a scene' do
      get edit_adm_scene_path(road)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(action="#{adm_scene_path(road)}"))

      patch adm_scene_path(road), params: { scene: { name: 'Kings Road' } }
      expect(response).to redirect_to(adm_scene_path(road))
      expect(road.reload.name).to eq 'Kings Road'

      patch adm_scene_path(road), params: { scene: { name: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'deleting' do
    it 'confirms, listing what goes with the scene, then deletes it and all that' do
      SceneFind.create!(scene: road, item: create(:item))
      road.notes.create!(user: ai, text: 'x', recorded_at: Time.current, client_id: 'n1')
      get delete_adm_scene_path(road)
      expect(response.body).to include('Delete Kingsroad?', '1 found item and 1 note')

      delete adm_scene_path(road)
      expect(response).to redirect_to(adm_scenes_path)
      expect(Scene.exists?(road.id)).to be false
      expect(SceneFind.count + SceneNote.count).to eq 0
    end

    it 'refuses while other scenes are inside it' do
      get delete_adm_scene_path(world)
      expect(response.body).to include('be deleted while other scenes are inside it')
      expect(response.body).not_to include('Delete scene</button>')

      delete adm_scene_path(world)
      expect(response).to redirect_to(delete_adm_scene_path(world))
      expect(Scene.exists?(world.id)).to be true
    end
  end

  it "names ADM's nav entries without icons" do
    get adm_scenes_path
    nav = response.body[%r{<nav class="main-navigation.*?</nav>}m]
    expect(nav).to include('>Scenes</span>', '>Sign Out</span>')
    expect(nav).not_to include('<svg')
  end

  it 'is only for root' do
    sign_in create(:user, :editor)
    get adm_scenes_path
    expect(response).to redirect_to(root_path)
    get adm_scene_path(road)
    expect(response).to redirect_to(root_path)
    patch adm_scene_path(road), params: { scene: { name: 'Kings Road' } }
    delete adm_scene_path(road)
    expect(road.reload.name).to eq 'Kingsroad'
  end
end
