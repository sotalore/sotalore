require 'rails_helper'

RSpec.describe EarnedSkill, type: :model do

  let!(:user) { create :user }
  let!(:avatar) { create :avatar, user: user }

  let(:skill) { Skill::BY_KEY.values.first }

  describe 'The basics' do
    let!(:earned_skill) { avatar.skills.create!(skill_key: skill.key) }

    it 'has the skill' do
      expect(earned_skill.skill).to eq skill
    end
  end
end
