# frozen-string-literal: true

module ItemsHelper

  def abstract_items_options
    Item.where(abstract: true).by_name
      .map { |i| [ i.name, i.id ]}
  end

  USE_ICONS = {
    'unknown' => 'question',
    'fuel' => 'fire',
    'tool' => 'wrench',
    'component' => 'cogs',
    'armor' => 'shield',
    'weapon' => 'sword',
    'decoration' => 'photo',
    'food' => 'apple_alt',
    'potion' => 'flask',
    'house' => 'home',
    'seed' => 'seedling',
    'pet-food' => 'bone',
  }.freeze

  USES_FOR_RECIPES = %w[ fuel tool ]

  SOURCE_ICONS = {
    'unknown' => 'question',
    'merchant' => 'money',
    'gathering' => 'scissors',
    'drop' => 'bullseye',
    'recipe' => 'book',
  }.freeze

  def item_price_tag(item, options={})
    return unless item.price

    price = item.price
    price = price * options[:count] if options.key?(:count)
    tag.span(class: item_css('text-golden-700', options)) do
      tag.span { safe_join([price.to_s, raw('&nbsp;gold')]) }
    end
  end

  def item_weight_tag(item, options={})
    return unless item.weight

    tag.span(class: item_css('text-grey-700', options)) do
      tag.span { "weight: #{item.weight}" }
    end
  end

  def item_abstract_tag(item, options={})
    return unless item.abstract

    icon_size = options[:large] || options[:size] == :lg ? :md : :xs
    tag.span(href: abstractions_url, class: item_css('text-sky-800 inline-flex gap-x-1', options)) do
      render_icon(:rectangles, size: icon_size, color: :current) + tag.span{ 'abstract' }
    end
  end

  def item_use_for_recipe_tag(item, options={})
    return unless USES_FOR_RECIPES.include?(item.use)

    item_use_tag(item, options)
  end

  def item_use_tag(item, options={})
    return if item.use_is_unknown? && options[:hide_unknown]
    return unless icon = USE_ICONS[item.use]

    label = item.use_is_unknown? ? 'unknown use' : item.use
    icon_size = options[:large] || options[:size] == :lg ? :md : :xs
    tag.span(class: item_css('text-sky-700 inline-flex gap-x-1', options)) do
      render_icon(icon, size: icon_size, color: :current) +
        tag.span { label }
    end
  end

  def item_gathering_tag(item, options={})
    craft_skill_tag(item.gathering_skill, options)
  end

  GATHERING_IMGS = {
    'field_dressing' => 'sota-icons/craft_field_dressing_small.png',
    'foraging' => 'sota-icons/craft_foraging_small.png',
    'forestry' => 'sota-icons/craft_forestry_small.png',
    'mining' => 'sota-icons/craft_mining_small.png',
  }.freeze

  def craft_skill_image_tag(skill, options={})
    img = GATHERING_IMGS[skill.to_param]
    return unless img

    if options[:large] || options[:size] == :lg
      sizes = 'h-6 w-6'
    else
      sizes = 'h-5 w-5'
    end
    tag.img(src: image_path(img), class: sizes)
  end

  def craft_skill_tag(skill, options={})
    return unless skill

    name = skill&.name || 'unknown'
    tag.span(class: item_css('text-green-700 inline-flex items-center gap-x-1', options)) do
      [
        craft_skill_image_tag(skill, options),
        tag.span { name }
      ].compact.join.html_safe
    end
  end

  def item_use_specific_tags(item, options={})
    case item.use
    when 'seed'
      generic_item_use_tag('yield: ', item.yield, options)
    when 'food', 'pet-food'
      generic_item_use_tag('buff slots used: ', item.buff_slots_used, options)
    end
  end

  private

  def generic_item_use_tag(label, value, options={})
    content_tag(:span, class: item_css('text-sky-700', options)) do
      h(label) + content_tag(:strong, value)
    end
  end

  ITEM_TAG_CSS_BASE = %w[
    bg-grey-200 border border-grey-300 rounded-full
    self-center inline-flex items-center whitespace-nowrap
  ].join(' ').freeze

  def item_css(extra=nil, options={})
    css = [ITEM_TAG_CSS_BASE]
    if options[:large] || options[:size] == :lg
      css << 'px-2.5 py-0.5 text-base'
    else
      css << 'px-1.5 py-0 text-sm'
    end
    css << extra if extra
    css.compact.join(' ')
  end

end
