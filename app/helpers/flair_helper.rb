# frozen-string-literal: true

module FlairHelper

  def flair_primary(text)
    flair_tag(:primary, :eye, text)
  end

  def flair_success(text)
    flair_tag(:success, :badge_check, text)
  end

  def flair_danger(text)
    flair_tag(:danger, :warning, text)
  end

  def flair_info(text)
    flair_tag(:info, :'information_circle', text)
  end

  def flair_warning(text)
    flair_tag(:warning, :warning, text)
  end

  private

  FLAIR_CSS = %w[
    inline-flex items-center border rounded pr-2
    whitespace-nowrap text-sm font-normal
  ].join(' ').freeze

  FLAIR_ICON_CSS = %w[
    h-full flex flex-row items-center justify-center
    px-1 mr-1 min-w-[19x]
  ].join(' ').freeze

  FLAIR_TYPE_CSS = {
    primary: 'text-sky-700 bg-sky-100 border-sky-500',
    danger: 'text-red-600 bg-red-100 border-red-500',
    warning: 'text-golden-700 bg-golden-100 border-golden-500',
    success: 'text-green-700 bg-green-100 border-green-500',
    info: 'text-purple-600 bg-purple-100 border-purple-500',
  }.with_indifferent_access.freeze

  FLAIR_ICON_TYPE_CSS = {
    primary: 'text-sky-100 bg-sky-700',
    danger: 'text-red-100 bg-red-600',
    warning: 'text-golden-100 bg-golden-700',
    success: 'text-green-100 bg-green-700',
    info: 'text-purple-100 bg-purple-600',
  }.with_indifferent_access.freeze

  def flair_tag(modifier, icon, text)
    content_tag(:span, class: "#{FLAIR_CSS} #{FLAIR_TYPE_CSS[modifier]}") do
      content_tag(:span, render_icon(icon, size: :sm), class: "#{FLAIR_ICON_CSS} #{FLAIR_ICON_TYPE_CSS[modifier]}") + text
    end
  end

end
