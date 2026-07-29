# frozen_string_literal: true

module SkillsHelper
  def current_skills_path(activity: 'adventuring')
    if params[:avatar_id] == 'none'
      return avatar_skills_path(avatar_id: 'none', activity: activity)
    end

    avatar = current_avatar
    return skills_path(activity: activity) unless avatar

    avatar_skills_path(avatar, activity: activity)
  end

  def current_avatar
    return nil if Current.user.null?

    if session[:current_avatar_id]
      avatar = Current.user.avatars.find_by(id: session[:current_avatar_id])
      if avatar.nil?
        # FIXME, should this be deleted on logout?
        session.delete(:current_avatar_id)
      else
        return avatar
      end
    end
    Current.user.avatars.detect(&:is_default)
  end

end
