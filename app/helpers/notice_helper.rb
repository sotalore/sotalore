# frozen-string-literal: true

module NoticeHelper

  def notice_info(message = nil, css_class: '', &block)
    notice_tag(:info, message, css_class: css_class, &block)
  end

  def notice_success(message = nil, &block)
    notice_tag(:success, message, &block)
  end

  def notice_warning(message = nil, &block)
    notice_tag(:warning, message, &block)
  end

  def notice_danger(message = nil, &block)
    notice_tag(:danger, message, &block)
  end

  def notice_error(message = nil, &block)
    notice_tag(:error, message, &block)
  end

  private

  ICON_FOR_TYPE = {
    info: "information_circle",
    success: "badge_check",
    warning: "warning",
    danger: "error",
    error: "error",
  }.with_indifferent_access.freeze

  NOTICE_CSS = %w[ my-4 mx-2 flex flex-row rounded ].join(' ').freeze
  NOTICE_ICON_CSS = %w[ flex items-center justify-center w-8 rounded-s ].join(' ').freeze

  NOTICE_TYPE_CSS = FlairHelper::FLAIR_TYPE_CSS
  NOTICE_ICON_TYPE_CSS = FlairHelper::FLAIR_ICON_TYPE_CSS

  def notice_tag(type, message = nil, css_class: '', &block)
    message = capture(&block) if block_given?

    content_tag(:div, class: "#{NOTICE_CSS} #{NOTICE_TYPE_CSS[type]} #{css_class}") do
      content_tag(:span, render_icon(ICON_FOR_TYPE[type]), class: "#{NOTICE_ICON_CSS} #{NOTICE_ICON_TYPE_CSS[type]}") +
      content_tag(:span, " #{message}".html_safe, class: "py-2 px-4 border rounded-e grow")
    end
  end

end
