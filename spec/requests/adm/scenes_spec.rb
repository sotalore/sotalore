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
    response.body.scan(%r{<a href="/scenes/\d+" target="_blank"[^>]*>([^<]+)</a>}).flatten
  end

  it 'lists scenes without finds, lowest tier first, leaving out the whole map' do
    get adm_scenes_path
    expect(response).to have_http_status(200)
    expect(names).to eq [ 'Solace Outskirts', 'Far Away', 'Spectral Forest' ]
    expect(response.body).to include('1 of 4 scenes have finds imported', %(href="/scenes/#{forest.id}/edit"))
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
    expect(response.body).to match(%r{<td class="pr-3 text-right">2</td><td class="pr-3 text-right">1</td><td class="text-right"></td>})
  end

  it 'is only for root' do
    sign_in create(:user, :editor)
    get adm_scenes_path
    expect(response).to redirect_to(root_path)
  end
end
