# frozen_string_literal: true

module Views::Comments::FlairHelper

  STANDARD_CLASSES = "text-sm text-grey-200 py-1px px-2 rounded".freeze

  ROLE_COLORS = {
    'root' => 'bg-purple-500',
    'editor' => 'bg-orange-500',
    'ai' => 'bg-teal-600',
  }.freeze

  ROLE_NAMES = {
    'root' => 'developer',
    'editor' => 'editor',
    'ai' => 'AI',
  }.freeze

  def user_flair_tag(user)
    if user.respond_to?(:bot?) && user.bot?
      role = 'ai'
    elsif user.has_role?('root')
      role = 'root'
    elsif user.has_role?('editor')
      role = 'editor'
    end

    if role
      color_class = ROLE_COLORS[role] || 'bg-grey-500'
      span(class: "#{STANDARD_CLASSES} #{color_class}") { ROLE_NAMES[role] }
    end
  end

end
