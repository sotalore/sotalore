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

  def current_skills_path(activity: 'adventuring')
    if params[:avatar_id] == 'none'
      return avatar_skills_path(avatar_id: 'none', activity: activity)
    end

    avatar = current_avatar
    return skills_path(activity: activity) unless avatar

    avatar_skills_path(avatar, activity: activity)
  end

  def current_avatar
    return nil if current_user.null?

    if session[:current_avatar_id]
      current_user.avatars.find(session[:current_avatar_id])
    else
      current_user.avatars.detect(&:is_default)
    end
  end

  def avatar_select_tag
    option_data = [['~ none ~', avatar_skills_path(avatar_id: 'none', activity: @activity)]] +
      @avatars.map { |a| [a.name, avatar_skills_path(avatar_id: a, activity: @activity)] }
    select_tag('avatar', options_for_select(option_data, request.path), class: 'py-0 h-8')
  end

end
