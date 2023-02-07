# frozen-string-literal: true

module ButtonHelper

  # migrated icons mapped from legacy font-awesome IDs
  ICONS = {
    info: HeroIconHelper::INFORMATION_CIRCLE,
    'caret-right': HeroIconHelper::CHEVRON_RIGHT,
    'pencil-alt': HeroIconHelper::PENCIL_ALT,
    'trash': HeroIconHelper::TRASH,
    'info-circle': HeroIconHelper::INFORMATION_CIRCLE,
    'check': HeroIconHelper::BADGE_CHECK,
    'warning': HeroIconHelper::WARNING,
    'error': HeroIconHelper::ERROR,
  }.with_indifferent_access


  def more_link_to(path, options={})
    options[:class] = 'MoreLink'
    link_to(path, options) do
      icon_tag('caret-right')
    end
  end

  def user_recipe_button(recipe)
    return unless current_user
    exists = current_user.user_recipes.find_by(recipe: recipe)
    css_class = "UserRecipeStar #{dom_id(recipe)}"
    if exists
      css_class += " UserRecipeStar--exists"
      link_to(user_user_recipe_path(exists, recipe_id: recipe), method: :delete, class: css_class, remote: true) do
        content_tag(:i, raw('&nbsp;'))
      end
    else
      link_to(user_user_recipes_path(recipe_id: recipe), method: :post, class: css_class, remote: true) do
        content_tag(:i, raw('&nbsp;'))
      end
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
    simple_icon_only_button(path, 'info', 'view', options)
  end

  def view_button_to(label, path, options={})
    options[:style] ||= 'primary'
    simple_button_with_icon(label, path, 'info', options)
  end

  def view_link_to(label, path, options={})
    options[:style] ||= 'primary'
    simple_link_with_icon(label, path, 'info', options)
  end

  def cancel_button_to(label, path, options={})
    default_button_to(label, path, options)
  end

  def new_button_to(label, path, options={})
    options[:style] ||= 'primary'
    simple_button_with_icon(label, path, 'plus', options)
  end

  def edit_icon_to(path, options={})
    simple_icon_only_button(path, 'pencil-alt', 'edit', options)
  end

  def edit_button_to(label, path, options={})
    options[:style] ||= 'primary'
    simple_button_with_icon(label, path, 'pencil-alt', options)
  end

  def back_button_to(label, path, options={})
    simple_button_with_icon(label, path, 'chevron-left', options)
  end

  def destroy_button_to(label, path, options={})
    options[:method] = :delete unless options.key?(:method)
    options[:data] ||= {}
    options[:data][:confirm] = 'Are you sure?' unless options[:data].key?(:confirm)
    simple_button_with_icon(label, path, 'trash', {style: 'danger'}.merge(options))
  end

  def destroy_icon_to(path, options={})
    options[:method] = :delete unless options.key?(:method)
    options[:data] ||= {}
    options[:data][:confirm] = 'Are you sure?' unless options[:data].key?(:confirm)
    simple_icon_only_button(path, 'trash', 'delete', {style: 'danger'}.merge(options))
  end

  def delete_button_to(label, path, options={})
    simple_button_with_icon(label, path, 'trash', {style: 'danger'}.merge(options))
  end

  def simple_icon_only_button(path, icon, title=nil, options={})
    options[:alt]   ||= title
    options[:title] ||= title
    options[:style] ||= 'default'
    add_button_css_classes(options)
    link_to(path, options) do
      icon_tag(icon)
    end
  end

  def icon_tag(icon, options={})
    if ICONS[icon]
      raise "Options passed to icon_tag" unless options == {}
      ICONS[icon]
    else
      options[:class] = "fas fa-#{icon} #{options[:class]}".strip
      content_tag(:i, "", options)
    end
  end

  def help_text_tag(text=nil, &block)
    if block_given?
      text = capture(&block)
    end
    if text.present?
      content_tag(:span, '?', class: 'HelpText', title: text, data: { toggle: 'tooltip' })
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
    if ICONS[icon]
      ICONS[icon] + " #{label}".html_safe
    else
      content_tag(:i, '', class: "fas fa-#{icon}") << " #{label}".html_safe
    end
  end
end
