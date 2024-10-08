# frozen-string-literal: true

module ButtonHelper

  def more_link_to(path, options={})
    link_to(path, options) do
      render_icon(:chevron_right)
    end
  end

  def edit_recipe_icon(recipe)
    if policy(recipe).edit?
      edit_icon_to(edit_recipe_path(recipe))
    end
  end

  def primary_button_to(label, path=nil, options={})
    if block_given?
      options, path = path, label
      label = capture { yield }
    end
    options = {style: 'primary'}.merge(options || {})
    add_button_css_classes(options)
    link_to(label, path, options)
  end

  def default_button_to(label, path=nil, options={})
    if block_given?
      options, path = path, label
      label = capture { yield }
    end
    options = {style: 'default'}.merge(options || {})
    add_button_css_classes(options)
    link_to(label, path, options)
  end

  def view_icon_to(path, options={})
    simple_icon_only_button(path, 'arrow_right_circle', 'view', options)
  end

  def view_link_to(label, path, options={})
    options[:style] ||= 'primary'
    simple_link_with_icon(label, path, 'information_circle', options)
  end

  def cancel_button_to(label, path, options={})
    default_button_to(label, path, options)
  end

  def new_button_to(label, path, options={})
    options[:style] ||= 'primary'
    simple_button_with_icon(label, path, 'plus', options)
  end

  def edit_icon_to(path, options={})
    simple_icon_only_button(path, 'pencil_alt', 'edit', options)
  end

  def edit_button_to(label, path, options={})
    options[:style] ||= 'primary'
    simple_button_with_icon(label, path, 'pencil_alt', options)
  end

  def back_button_to(label, path, options={})
    simple_button_with_icon(label, path, 'chevron_left', options)
  end

  def destroy_button_to(label, path, options={})
    options[:data] ||= {}
    options[:data][:turbo_method] ||= :delete
    options[:data][:turbo_confirm] = 'Are you sure?' unless options[:data].key?(:turbo_confirm)
    simple_button_with_icon(label, path, 'trash', {style: 'danger'}.merge(options))
  end

  def destroy_icon_to(path, options={})
    options[:data] ||= {}
    options[:data][:turbo_method] ||= :delete
    options[:data][:turbo_confirm] = 'Are you sure?' unless options[:data].key?(:turbo_confirm)
    simple_icon_only_button(path, 'trash', 'delete', {style: 'danger'}.merge(options))
  end

  def simple_icon_only_button(path, icon, title=nil, options={})
    options[:alt]   ||= title
    options[:title] ||= title
    options[:style] ||= 'default'
    options[:size]  ||= :sm
    add_button_css_classes(options)
    link_to(path, options) do
      render_icon(icon, size: :sm)
    end
  end

  def add_button_css_classes(options)
    str = "Button #{options[:class]}".strip
    if options.key?(:size)
      size = options.delete(:size)
      str << " Button--#{size}"
    end

    style = options.delete(:style) { 'primary' }
    str << " Button--#{style}"
    options[:class] = str.strip
    options
  end

  def add_link_css_classes(options)
    str = "Link #{options[:class]}".strip
    if options.key?(:size)
      size = options.delete(:size)
      str << " Link--#{size}"
    end

    style = options.delete(:style) { 'primary' }
    str << " Link--#{style}"
    options[:class] = str.strip
    options
  end

  private
  def simple_button_with_icon(label, path, icon, options={})
    options[:style] ||= 'default'
    add_button_css_classes(options)
    link_to(path, options) { icon_plus_label(icon, label) }
  end

  def simple_link_with_icon(label, path, icon, options={})
    options[:style] ||= 'default'
    add_link_css_classes(options)
    link_to(path, options) { icon_plus_label(icon, label) }
  end

  def icon_plus_label(icon, label)
    render_icon(icon, size: :sm) + " #{label}".html_safe
  end
end
