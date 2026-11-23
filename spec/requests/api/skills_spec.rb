require 'rails_helper'

RSpec.describe "Api::V1::Skills", type: :request do
  let(:admin) { create(:user, :root) }
  let(:ai)    { User.create_ai_account!(name: 'Companion') }

  def headers(scopes = %w[ read ])
    { 'Authorization' => "Bearer #{ApiToken.issue!(user: ai, name: 't', scopes: scopes, created_by: admin).last}" }
  end

  it 'lists every skill the site knows, with the game id and key to match on' do
    get api_v1_skills_path, headers: headers
    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body['skills'].size).to eq Skill::BY_KEY.size
    expect(body['skills']).to include(
      { 'id' => 10001, 'key' => 'gathering~mining~mining', 'name' => 'Mining', 'activity' => 'crafting',
        'category' => 'gathering', 'school' => 'mining', 'xp_factor' => 1.0,
        'game_id' => 2041, 'game_key' => 'MiningProficiency' }
    )
    expect(body['skills'].first['activity']).to eq 'adventuring'
    expect(body['game_schools']).to include('moon' => 'lunar')
  end

  it 'matches every skill in the game-skills example by game id' do
    get api_v1_skills_path, headers: headers
    site = response.parsed_body['skills'].index_by { _1['game_id'] }
    game = JSON.parse(Rails.root.join('spec/fixtures/plugin-examples/sotalore-game-skills.json').read)['skills']
    expect(game.map { _1['id'] } - site.keys).to eq []
  end

  it 'needs the read scope' do
    get api_v1_skills_path, headers: headers(%w[ upload ])
    expect(response).to have_http_status(:forbidden)
  end
end
