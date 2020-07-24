# frozen-string-literal: true

module UsersHelper

  def user_flair_tag(user)
    if user.has_role?('root')
      role = 'developer'
    elsif user.has_role?('editor')
      role = 'editor'
    end

    if role
      content_tag(:span, role, class: "UserFlair UserFlair--#{role}")
    end
  end

end
