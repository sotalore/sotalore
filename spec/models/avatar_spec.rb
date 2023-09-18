require 'rails_helper'

RSpec.describe Avatar, type: :model do

  let(:user) { create :user }

  describe 'making avatar a default' do

    let!(:av1) { create :avatar, user: user }
    let!(:av2) { create :avatar, user: user }

    it 'unsets the previous default' do
      av1.update!(is_default: true)
      av2.update!(is_default: true)
      av1.reload
      assert !av1.is_default
    end
  end

  describe "#ignore_skill!" do
    let(:avatar) { create :avatar }
    let(:skill) { Skill.find(1) }

    it "ignores the skill" do
      expect { avatar.ignore_skill!(skill) }
        .to change { avatar.reload.ignored_skills }.from([]).to([skill.id])
    end
  end

  describe "#ignoring_skill?" do
    let(:avatar) { build :avatar }
    let(:skill) { Skill.find(1) }

    it "detects ignored skills" do
      expect { avatar.ignored_skills << skill.id }
        .to change { avatar.ignoring_skill?(skill) }
        .from(false).to(true)
    end
  end

  describe "#reveal_skill!" do
    let(:avatar) { create :avatar }
    let(:skill) { Skill.find(1) }

    it "ignores the skill" do
      avatar.ignore_skill!(skill)
      expect { avatar.reveal_skill!(skill) }
        .to change { avatar.reload.ignored_skills }.from([skill.id]).to([])
    end
  end

end
