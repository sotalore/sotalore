# frozen_string_literal: true

module Views::NoticeHelper
  include Views::FlairHelper
  include Phlex::Rails::Helpers::Flash

  FLASH_TYPES = {
    alert: :warning,
    error: :danger,
    notice: :info
  }.with_indifferent_access.freeze

  def render_flash_messages
    flash.each do |type, message|
      notice_tag(FLASH_TYPES[type] || type, message)
    end
  end

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

  private

  ICON_FOR_TYPE = {
    info: "information_circle",
    success: "badge_check",
    warning: "warning",
    danger: "error",
    error: "error",
  }.with_indifferent_access.freeze

  NOTICE_CSS = %w[ my-4 mx-2 flex flex-row border rounded ].join(' ').freeze
  NOTICE_ICON_CSS = %w[ flex items-center justify-center w-8 rounded-s ].join(' ').freeze

  NOTICE_TYPE_CSS = Views::FlairHelper::FLAIR_TYPE_CSS
  NOTICE_ICON_TYPE_CSS = Views::FlairHelper::FLAIR_ICON_TYPE_CSS

  def notice_tag(type, message = nil, css_class: '', &block)
    message = capture(&block) if block_given?

    div(class: "#{NOTICE_CSS} #{NOTICE_TYPE_CSS[type]} #{css_class}") do
      span(class: "#{NOTICE_ICON_CSS} #{NOTICE_ICON_TYPE_CSS[type]}") do
        render_icon(ICON_FOR_TYPE[type])
      end
      span(class: "py-2 px-4 rounded-e grow") do
        raw(safe(" #{message}"))
      end
    end
  end

end
