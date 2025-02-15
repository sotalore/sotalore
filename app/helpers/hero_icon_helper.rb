# frozen_string_literal: true

module HeroIconHelper

  def render_icon(name, size: :md, color: :current, css_class: '')
    icon = ::Components::Icons.const_get(name.to_s.camelize)
    render icon.new(size: size, color: color, class: css_class)
  end

end

