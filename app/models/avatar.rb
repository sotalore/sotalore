class Avatar < ApplicationRecord

  belongs_to :user, inverse_of: :avatars
  has_many :skills, class_name: 'EarnedSkill', inverse_of: :avatar, dependent: :delete_all

  validates :name, presence: true

  before_save do
    if is_default
      user.avatars.where.not(id: id).update(is_default: false)
    end
  end

  def ignore_skill!(skill)
    unless ignored_skills.include?(skill.id)
      ignored_skills << skill.id
      self.save!
    end
  end

  def ignoring_skill?(skill)
    self.ignored_skills.include?(skill.id)
  end

  def reveal_skill!(skill)
    self.ignored_skills.delete(skill.id)
    self.save!
  end

  # This preloads skills, to be used when viewing them all
  def current_skills
    unless @current_skills
      @current_skills = Hash.new(EarnedSkill.new)
      skills.each do |earned_skill|
        @current_skills[earned_skill.skill_key] = earned_skill
      end
    end
    @current_skills
  end

end
