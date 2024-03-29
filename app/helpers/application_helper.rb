# frozen_string_literal: true

module ApplicationHelper
  def page_heading(heading)
    if heading && page_title.blank?
      page_title(heading)
    end
    content_tag(:div, class: 'heading-container') do
      concat(content_tag(:div, class: 'heading') do
        content_tag(:h3, heading)
      end)
      yield if block_given?
    end
  end

  def page_heading_controls(&block)
    content_tag(:div, 'heading-controls', &block)
  end

  def title(title)
    puts "Do something with the title"
  end

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


  def teachable_options
    Recipe.teachables.keys.map { |k| [ t(k, scope: [ :helpers, :label, :recipe, :teachables ]), k ] }
  end

  def scene_level(scene)
    return unless scene
    "#{scene.level}#{scene.level_plus ? '+' : ''}"
  end

  def page_heading_tab(current, name, path)
    link_to_unless(current, name, path, class: "PageTabs-tab") do |name|
      content_tag(:span, name, class: "PageTabs-tab PageTabs-current")
    end
  end

  def can_manage_item?(item)
    policy(:verification).edit? || policy(item).destroy?
  end
end
