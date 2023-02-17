# frozen-string-literal: true

module UsersHelper

  STANDARD_CLASSES = "text-sm text-grey-200 py-1px px-2 rounded".freeze

  ROLE_COLORS = {
    'root' => 'bg-purple-500',
    'editor' => 'bg-orange-500'
  }.freeze

  ROLE_NAMES = {
    'root' => 'developer',
    'editor' => 'editor',
  }.freeze

  def user_flair_tag(user)
    if user.has_role?('root')
      role = 'root'
    elsif user.has_role?('editor')
      role = 'editor'
    end

    if role
      color_class = ROLE_COLORS[role] || 'bg-grey-500'
      content_tag(:span, ROLE_NAMES[role], class: "#{STANDARD_CLASSES} #{color_class}")
    end
  end

end
