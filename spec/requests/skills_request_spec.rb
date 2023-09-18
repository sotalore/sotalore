require 'rails_helper'

RSpec.describe 'Skills', type: :request do

  describe "INDEX with no user" do
    it "adventuring returns success" do
      get skills_path(activity: 'adventuring')
      expect(response).to have_http_status(:ok)
    end

    it "crafting returns success" do
      get skills_path(activity: 'crafting')
      expect(response).to have_http_status(:ok)
    end
  end


  describe 'A logged in user with a current avatar' do
    let!(:user) { create :user }
    let!(:avatar) { create :avatar, user: user }

    let(:skill) { Skill::BY_KEY.values.first }

    before        { sign_in user }

    describe "INDEX" do
      it "adventuring returns success" do
        get avatar_skills_path(avatar, activity: 'adventuring')
        expect(response).to have_http_status(:ok)
      end

      it "crafting returns success" do
        get avatar_skills_path(avatar, activity: 'crafting')
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PATCH a not-yet-set EarnedSkill' do

      it 'creates a new EarnedSkill' do
        expect(avatar.skills).to be_empty

        patch avatar_skill_path(avatar, id: skill.key), params: { skill: { current: 123 }}
        expect(response).to have_http_status(:ok)

        earned_skill = avatar.skills.reload.first
        expect(earned_skill).to be_present
      end


      it 'does not create an EarnedSkill for a bad key' do
        expect(avatar.skills).to be_empty

        patch avatar_skill_path(avatar, id: 'bad~key'), params: { skill: { current: 123 }}
        expect(response).to have_http_status(:bad_request)

        expect(avatar.skills.select(&:persisted?)).to be_empty
      end
    end

    describe "ignore" do
      it "adds the skill to the avatar's ignore list" do
        patch ignore_avatar_skill_path(avatar, id: skill.id)

        expect(response).to redirect_to(avatar_skills_path(avatar))

        avatar.reload
        expect(avatar.ignored_skills).to include(skill.id)
      end
    end

    describe "reveal" do
      it "adds the skill to the avatar's ignore list" do
        avatar.ignore_skill!(skill)

        patch reveal_avatar_skill_path(avatar, id: skill.id)

        expect(response).to redirect_to(avatar_skills_path(avatar, show_all: true))

        avatar.reload
        expect(avatar.ignored_skills).to_not include(skill.id)
      end
    end
  end

end
