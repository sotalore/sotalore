require 'rails_helper'

RSpec.describe SkillsHelper, type: :helper do


  describe '#current_skills_path' do
    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    context 'With no current user' do
      let(:current_user) { NullUser.new }

      it "is the skills path" do
        expect(helper.current_skills_path).to eq(skills_path)
      end

      it "is the crafting skills path, when specified" do
        expect(helper.current_skills_path(activity: 'crafting')).to eq(skills_path(activity: 'crafting'))
      end
    end

    context 'With a current user, with no avatars' do
      let(:current_user) { create(:user) }

      it "is the skills path" do
        expect(helper.current_skills_path).to eq(skills_path)
      end

      it "is the crafting skills path, when specified" do
        expect(helper.current_skills_path(activity: 'crafting')).to eq(skills_path(activity: 'crafting'))
      end
    end

    context 'With a current user, with a default avatar' do
      let(:current_user) { create(:user) }
      let!(:default_avatar) { create(:avatar, user: current_user, is_default: true) }

      it "is the avatar skills path" do
        expect(helper.current_skills_path).to eq(avatar_skills_path(default_avatar))
      end

      it "is the crafting skills path, when specified" do
        expect(helper.current_skills_path(activity: 'crafting'))
          .to eq(avatar_skills_path(default_avatar, activity: 'crafting'))
      end
    end

    context 'With a current user, and a default avatar, and a current_avatar' do
      let(:current_user) { create(:user) }
      let!(:default_avatar) { create(:avatar, user: current_user, is_default: true) }
      let!(:current_avatar) { create(:avatar, user: current_user, is_default: false) }

      before do
        helper.session[:current_avatar_id] = current_avatar.id
      end

      it "is the current_avatar skills path" do
        expect(helper.current_skills_path).to eq(avatar_skills_path(current_avatar))
      end

      it "is the current_avatar crafting skills path, when specified" do
        expect(helper.current_skills_path(activity: 'crafting'))
          .to eq(avatar_skills_path(current_avatar, activity: 'crafting'))
      end
    end

  end
end
