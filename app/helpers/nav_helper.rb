# frozen-string-literal: true

module NavHelper
  def portal_nav_link_to(text, url, icon, options={})
    count = options.fetch(:count, 0)

    options = {
      active: options.fetch(:active, nil),
      class: "PortalNav-link",
      class_active: "is-active"
    }

    if defined?(@portal_nav_active_link)
      options[:active] ||= url == @portal_nav_active_link
    end

    active_link_to(url, options) do
      html = icon_tag(icon, class: 'PortalNav-icon')

      if count.positive?
        html << content_tag(:span, count.to_s, class: 'PortalNav-badge')
      end

      html + text
    end
  end

  def portal_nav_activate_link(url)
    @portal_nav_active_link = url
    nil
  end

  def division_tab_to(text, url, options = {})
    options[:class] = 'DivisionNav-tab'
    active_link_to(text, url, options)
  end

  def division_search(url, placeholder = 'Search')
    content_tag(:form, class: 'DivisionNav-search', action: url, method: "GET") do
      icon_tag(:search, class: 'DivisionNav-searchIcon') +
      tag(:input, type: "text", placeholder: placeholder, name: "q", value: params[:q], class: "DivisionNav-searchInput #{params[:q].present? ? 'has-value' : ''}" )
    end
  end

  def section_title_to(text, url)
    title(text)
    content_for(:section_header) do
      content_tag(:h2, class: 'SectionNav-title') do
        link_to(text, url)
      end
    end
  end

  def section_title(text=nil, &block)
    if block_given?
      text = capture(&block)
    end

    title(strip_tags(text.to_s))

    content_for(:section_header) do
      content_tag(:h2, text, class: 'SectionNav-title')
    end
  end

  def section_buttons
    content_for(:section_buttons) do
      content_tag(:nav, class: 'SectionNav-buttons') do
        yield
      end
    end
  end

  def section_tabs
    content_for(:section_header) do
      content_tag(:nav, class: 'SectionNav-tabs') do
        yield
      end
    end
  end

  def section_tab_to(text, url, options = {})
    options[:class] = 'SectionNav-tab'
    options[:class] += ' is-disabled' if options[:disabled]
    active_link_to(text, url, options)
  end

  def sub_section_title_to(text, url)
    content_for(:sub_section_header) do
      content_tag(:h3, class: 'SubSectionNav-title') do
        link_to(text, url)
      end
    end
  end

  def sub_section_title(text)
    content_for(:sub_section_header) do
      content_tag(:h3, text, class: 'SubSectionNav-title')
    end
  end

  def sub_section_buttons
    content_for(:sub_section_buttons) do
      content_tag(:nav, class: 'SubSectionNav-buttons') do
        yield
      end
    end
  end
end
