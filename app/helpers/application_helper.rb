# frozen_string_literal: true

module ApplicationHelper
  FLASH_TYPES = {
    alert: :warning,
    error: :danger,
    notice: :info
  }.with_indifferent_access.freeze

  def render_flash_messages
    flash.map { |type, message|
      notice_tag(FLASH_TYPES[type] || type, message)
    }.join.html_safe
  end

  def formatted_body(str)
    return nil if str.blank?
    content_tag(:div, class: 'prose') do
      Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true))
        .render(str).html_safe
    end
  end


  def scene_level(scene)
    return unless scene
    "#{scene.level}#{scene.level_plus ? '+' : ''}"
  end

end
