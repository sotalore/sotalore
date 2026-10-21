require 'rails_helper'

RSpec.describe 'Hidden skills', type: :request do
  let!(:user) { create :user }
  let!(:avatar) { create :avatar, user: user }
  let(:skill) { Skill::BY_KEY.values.first }
  let(:school) { Skill.in_school('heavy-armor') }
  let(:json) { { 'Accept' => 'application/json' } }

  it "needs a signed-in user" do
    get avatar_hidden_skills_path(avatar, activity: 'adventuring')
    expect(response).to redirect_to(new_user_session_path)
  end

  context "signed in" do
    before { sign_in user }

    describe "INDEX" do
      it "lists every skill, checking the hidden ones" do
        avatar.ignore_skill!(skill)

        get avatar_hidden_skills_path(avatar, activity: 'adventuring')
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('1 hidden')
        expect(response.body).to include(reveal_avatar_skill_path(avatar, skill.id))
        expect(response.body).to include(hide_avatar_skill_school_path(avatar, 'heavy-armor'))
        expect(response.body).to include(reveal_avatar_skill_school_path(avatar, 'heavy-armor'))
      end

      it "lists crafting skills" do
        get avatar_hidden_skills_path(avatar, activity: 'crafting')
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Blacksmithing')
      end

      it "is not found for another player's avatar" do
        get avatar_hidden_skills_path(create(:avatar), activity: 'adventuring')
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "hide and reveal" do
      it "hides a skill" do
        patch hide_avatar_skill_path(avatar, skill.id), headers: json
        expect(response).to have_http_status(:no_content)
        expect(avatar.reload.ignored_skills).to eq([ skill.id ])
      end

      it "reveals a skill" do
        avatar.ignore_skills!(school + [ skill ])
        patch reveal_avatar_skill_path(avatar, skill.id), headers: json
        expect(response).to have_http_status(:no_content)
        expect(avatar.reload.ignored_skills).to match_array(school.map(&:id))
      end

      it "is not found for an unknown skill" do
        patch hide_avatar_skill_path(avatar, 99_999), headers: json
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "hide_school and reveal_school" do
      it "hides all of a school, even with some already hidden" do
        avatar.ignore_skill!(school.first)
        patch hide_avatar_skill_school_path(avatar, 'heavy-armor'), headers: json
        expect(response).to have_http_status(:no_content)
        expect(avatar.reload.ignored_skills).to match_array(school.map(&:id))
      end

      it "reveals all of a school, leaving other skills hidden" do
        avatar.ignore_skills!(school.first(2) + [ skill ])
        patch reveal_avatar_skill_school_path(avatar, 'heavy-armor'), headers: json
        expect(avatar.reload.ignored_skills).to eq([ skill.id ])
      end

      it "goes back to the page without JavaScript" do
        page = avatar_hidden_skills_url(avatar, activity: 'adventuring')
        patch hide_avatar_skill_school_path(avatar, 'heavy-armor'), headers: { 'HTTP_REFERER' => page }
        expect(response).to redirect_to(page)
        expect(response).to have_http_status(:see_other)
      end

      it "is not found for an unknown school" do
        patch hide_avatar_skill_school_path(avatar, 'knitting'), headers: json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
