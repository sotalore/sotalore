# frozen_string_literal: true

class Views::Layouts::Base < Views::Base

  register_output_helper :active_link_to

  def site_nav_link_to(text, url, icon, options={})
    options = {
      active: options.fetch(:active, nil),
      class: "site-nav-link",
      class_active: "is-active",
      alt: text,
      title: text,
      data: options.fetch(:data, {})
    }

    if view_context.instance_variable_defined?(:@portal_nav_active_link)
      options[:active] ||= url == view_context.instance_variable_get(:@portal_nav_active_link)
    else
      options[:active] = :inclusive
    end

    active_link_to(url, options) do
      render_icon(icon, color: :current)
      span(class: 'hidden lg:inline') { text }
    end
  end

end
