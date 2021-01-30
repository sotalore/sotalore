class EarnedSkill < ApplicationRecord
  belongs_to :avatar, inverse_of: :skills

  validate :valid_skill_key, on: :create

  def skill
    Skill.find(skill_key)
  end

  private

  def valid_skill_key
    if !skill
      self.errors.add(:skill_key, 'is invalid')
    end
  end
end
