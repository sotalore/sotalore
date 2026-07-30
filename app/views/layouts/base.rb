# frozen_string_literal: true

class Views::Layouts::Base < Views::Base

  register_output_helper :active_link_to

  THEME_OPTIONS = {
    "light" => "sun",
    "dark" => "moon",
    "system" => "computer_desktop",
  }.freeze

  # Applied to <html> before first paint so the page never flashes the wrong
  # theme. The `theme` Stimulus controller (on the top-bar switcher) takes
  # over afterwards and keeps this in sync with user choice / OS changes.
  THEME_INIT_SCRIPT = <<~JS.freeze
    (function () {
      try {
        var stored = localStorage.getItem('theme');
        var dark = stored === 'dark' || (stored !== 'light' && window.matchMedia('(prefers-color-scheme: dark)').matches);
        document.documentElement.classList.toggle('dark', dark);
      } catch (e) {}
    })();
  JS

  def theme_init_script
    script { raw safe(THEME_INIT_SCRIPT) }
  end

  def theme_switcher
    div(class: "theme-switcher mr-4", data: { controller: "theme" }) do
      THEME_OPTIONS.each do |mode, icon|
        button(
          type: "button",
          class: "theme-switcher-option",
          title: mode.capitalize,
          aria_label: "Use #{mode} theme",
          data: { theme_target: "option", action: "theme#set", theme_mode_param: mode }
        ) do
          render_icon(icon, size: :sm, color: :current)
        end
      end
    end
  end

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
