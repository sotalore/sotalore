# frozen_string_literal: true

module SkillsHelper
  def avatar_visible_skills(avatar, skills)
    return skills unless avatar

    skills.select { |s| !avatar.ignoring_skill?(s) }
  end

  def toggle_skill_button(avatar, skill)
    return unless avatar

    if @avatar.ignoring_skill?(skill)
      icon = render_icon('eye_slash', size: :sm)
      path = reveal_avatar_skill_path(@avatar, skill.id)
    else
      icon = render_icon('eye', size: :sm)
      show_all_param = params.key?(:show_all) ? { show_all: true } : {}
      path = ignore_avatar_skill_path(@avatar, skill.id, **show_all_param)
    end

    button_to(icon, path, class: 'text-slorange-500', method: :patch, tabindex: "-1", form: { class: 'inline'})
  end
end
