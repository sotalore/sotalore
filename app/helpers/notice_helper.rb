# frozen-string-literal: true

module NoticeHelper

  ICON_FOR_TYPE = {
    info: "info-circle",
    success: "check",
    warning: "warning",
    danger: "error",
    error: "error",
  }.with_indifferent_access.freeze

  def notice_info(message = nil, &block)
    notice_tag(:info, message, &block)
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

  def notice_tag(type, message = nil, &block)
    if block_given?
      message = capture(&block)
    end

    content_tag(:div, class: "Notice Notice--#{type}") do
      content_tag(:span, icon_tag(ICON_FOR_TYPE[type]), class: "Notice-icon") +
      content_tag(:span, " #{message}".html_safe, class: "Notice-text")
    end
  end

end
