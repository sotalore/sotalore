# frozen-string-literal: true

module NavHelper

  def site_nav_link_to(text, url, icon, options={})

    options = {
      active: options.fetch(:active, nil),
      class: "site-nav-link",
      class_active: "is-active"
    }

    if defined?(@portal_nav_active_link)
      options[:active] ||= url == @portal_nav_active_link
    else
      options[:active] = :inclusive
    end

    active_link_to(url, options) do
      icon + content_tag(:span, text, class: 'hidden lg:inline')
    end
  end

  def site_nav_activate_link(url)
    @portal_nav_active_link = url
    nil
  end

end
