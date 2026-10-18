require 'rails_helper'

RSpec.describe 'SkillImports', type: :request do
  let(:user) { create(:user) }
  let(:avatar) { create(:avatar, user: user, name: 'Gravidy') }
  let(:deflect) { Skill.find_by_game_id(131) }
  before { sign_in user }

  it 'takes a pasted code, shows the changes, and saves them' do
    get avatar_skills_path(avatar, activity: 'adventuring')
    expect(response.body).to include(%(href="#{new_avatar_skill_import_path(avatar)}"))

    get new_avatar_skill_import_path(avatar)
    expect(response).to have_http_status(200)
    expect(response.body).to include('Importing skill levels into', '/slskills')
    expect(response.body).to match(%r{<option[^>]*value="#{new_avatar_skill_import_path(avatar)}"[^>]*>Gravidy</option>})

    code = skill_code({ 131 => 90, 1 => 20 })
    post preview_avatar_skill_import_path(avatar), params: { code: code }
    expect(response).to have_http_status(200)
    expect(response.body).to include('Current levels to change (2)', 'Deflect', 'Gust', 'Save these levels')
    expect(response.body).not_to include('colspan') # a short list isn't grouped
    expect(avatar.skills.count).to eq 0

    post avatar_skill_import_path(avatar), params: { code: code, clear_untrained: '1' }
    expect(response).to redirect_to(avatar_skills_path(avatar, activity: 'adventuring'))
    expect(flash[:notice]).to eq 'Updated 2 skills for Gravidy from the game.'
    expect(avatar.skills.find_by(skill_key: deflect.key).current).to eq 90
  end

  it 'reads a whole code the plugin made' do
    post preview_avatar_skill_import_path(avatar), params: { code: file_fixture('skill-code.txt').read }
    expect(response.body).to include('Current levels to change (338)')
    schools = response.body.scan(/<th colspan="3"[^>]*>([^<]+)</).flatten
    expect(schools.first(3)).to eq %w[ Shield Polearm Blades ]
    expect(schools.last).to eq 'Tailoring'
    expect(response.body).not_to include("doesn't know yet")
  end

  it 'asks for the missing pages' do
    pages = skill_code_pages({ 131 => 90, 1 => 20 }, per_page: 1)
    post preview_avatar_skill_import_path(avatar), params: { code: pages.second }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('Still missing page 1 of 2.')

    post avatar_skill_import_path(avatar), params: { code: pages.second }
    expect(response).to redirect_to(new_avatar_skill_import_path(avatar))
    expect(avatar.skills.count).to eq 0
  end

  it 'explains itself without an avatar to import into' do
    get skills_import_path
    expect(response.body).to include('Bring your skill levels in from the game', 'Create an avatar')

    avatar
    get new_avatar_skill_import_path(avatar_id: 'none')
    expect(response.body).to include('Choose the avatar to import into')
    expect(response.body).not_to include('/slskills')

    post preview_avatar_skill_import_path(avatar_id: 'none'), params: { code: skill_code({ 131 => 90 }) }
    expect(response).to redirect_to(skills_import_path)
  end

  it 'explains itself to someone signed out' do
    sign_in NullUser.new
    get skills_import_path
    expect(response).to have_http_status(200)
    expect(response.body).to include('Bring your skill levels in from the game', 'Sign in')
    get skills_path(activity: 'adventuring')
    expect(response.body).to include(%(href="#{skills_import_path}"))
  end

  it 'is only for the avatar\'s player' do
    other = create(:avatar)
    get new_avatar_skill_import_path(other)
    expect(response).to have_http_status(:not_found)
    post avatar_skill_import_path(other), params: { code: skill_code({ 131 => 90 }) }
    expect(other.skills.count).to eq 0
  end
end
