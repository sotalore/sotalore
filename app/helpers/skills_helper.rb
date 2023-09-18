# frozen_string_literal: true

module SkillsHelper
  def avatar_visible_skills(avatar, skills)
    return skills unless avatar

    skills.select { |s| !avatar.ignoring_skill?(s) }
  end
end
