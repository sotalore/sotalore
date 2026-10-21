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
    ignore_skills!([ skill ])
  end

  # Ignores a whole school (or any set) of skills at once. The hidden skills
  # page saves each click as it's made, so the row is locked to keep quick
  # clicks from overwriting each other's changes.
  def ignore_skills!(skills)
    with_lock do
      self.ignored_skills |= skills.map(&:id)
      save! if changed?
    end
  end

  def ignoring_skill?(skill)
    self.ignored_skills.include?(skill.id)
  end

  def reveal_skill!(skill)
    reveal_skills!([ skill ])
  end

  def reveal_skills!(skills)
    with_lock do
      self.ignored_skills -= skills.map(&:id)
      save! if changed?
    end
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
