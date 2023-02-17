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
  def item_use_for_recipe_tag(item, options={})
    return unless USES_FOR_RECIPES.include?(item.use)
    item_use_tag(item, options)
  end

  def item_use_tag(item, options={})
    return nil if item.use_is_unknown? && options[:hide_unknown]
    if icon = USE_ICONS[item.use]
      label = item.use_is_unknown? ? 'unknown use' : item.use
      css_class = "Item-useTag Item-useTag--#{item.use}"
      css_class += " Item-useTag--large" if options[:large]
      icon_size = options[:large] ? :md : :xs
      content_tag(:span, class: css_class) do
        render_icon(icon, size: icon_size, color: :current) + " " + label
      end
    end
  end

  SOURCE_ICONS = {
    'unknown' => 'question',
    'merchant' => 'money',
    'gathering' => 'scissors',
    'drop' => 'bullseye',
    'recipe' => 'book',
  }.freeze

  def item_price_tag(item, options={})
    if item.price
      price = item.price
      price = price * options[:count] if options.key?(:count)
      css_class = "Item-priceTag"
      css_class += " Item-priceTag--large" if options[:large]
      content_tag(:span, class: css_class) do
        content_tag(:span, price, class: "Item-priceTag-price") +
          content_tag(:span, raw('&nbsp;gold'), class: "Item-priceTag-symbol")
      end
    end
  end

  def item_weight_tag(item, options={})
    if item.weight
      weight = item.weight
      css_class = "Item-weightTag"
      css_class += " Item-weightTag--large" if options[:large]
      content_tag(:span, class: css_class) do
        content_tag(:span, "weight: #{weight}", class: "Item-weightTag-weight")
      end
    end
  end

  def item_gathering_tag(item, options={})
    craft_skill_tag(item.gathering_skill, options)
  end

  def item_abstract_tag(item, options={})
    if item.abstract
      css_class = "Item-abstractTag"
      css_class += " Item-abstractTag--large" if options[:large]
      icon_size = options[:large] ? :md : :xs
      content_tag(:a, href: abstractions_url) do
        content_tag(:span, class: css_class) do
          render_icon(:rectangles, size: icon_size) + " " + content_tag(:span, 'abstract', class: "Item-abstractTag-abstract")
        end
      end
    end
  end

  def craft_skill_tag(skill, options={})
    if skill
      css_class = "Item-gatheringTag"
      css_class += " Item-gatheringTag--#{skill.to_param}"  if skill
      css_class += " Item-gatheringTag--large" if options[:large]
      name = skill&.name || 'unknown'
      content_tag(:span, class: css_class) do
        content_tag(:span, name, class: "Item-gatheringTag-name")
      end
    end
  end

  def item_use_specific_tags(item)
    case item.use
    when 'seed'
      generic_item_use_tag('yield: ', item.yield)
    when 'food', 'pet-food'
      generic_item_use_tag('buff slots used: ', item.buff_slots_used)
    end
  end

  def generic_item_use_tag(label, value)
    css_class = "Item-useTag Item-useTag--large"
    content_tag(:span, class: css_class) do
      h(label) + content_tag(:strong, value)
    end
  end
end
