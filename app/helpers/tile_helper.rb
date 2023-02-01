# frozen-string-literal: true

TILE_TAILWIND = Hash.new('border-grey-300').merge({
  info: ' border-purple-500',
}).with_indifferent_access

TILE_HEADING_TAILWIND = Hash.new(' border-grey-300').merge({
  info: ' bg-purple-100 border-purple-500 text-purple-500',
}).with_indifferent_access

module TileHelper

  def lead_in(&block)
    content_tag(:div, class: "tile-lead-in Tile-leadIn", &block)
  end

  def tile_with_heading(heading, subheading = nil, options={}, &block)
    if Hash === subheading
      options, subheading = subheading, nil
    end
    tile(options[:type]) do
      tile_heading(heading, subheading: subheading, type: options[:type]) +
      tile_body(&block)
    end
  end

  def tile(type=nil, options={}, &block)
    css_class = "#{options[:class]} Tile m-2 bg-grey-100 border"
    css_class += " Tile--#{type}" if type
    css_class += TILE_TAILWIND[type]

    options[:class] = css_class
    content_tag(:div, options, &block)
  end

  def tile_body(type=nil, &block)
    css_class = "Tile-body p-4"
    css_class += " Tile-body--#{type}" if type
    content_tag(:div, class: css_class, &block)
  end

  def tile_heading(heading, subheading: nil, type: nil, &block)
    if block_given?
      controls = content_tag(:div, class: "Tile-controls", &block)
    end

    content_tag(:div, class: "Tile-heading p-4 border-b border-dashed #{TILE_HEADING_TAILWIND[type]}") do
      content_tag(:h3) do
        content_tag(:span, heading) + ' ' +
          content_tag(:span, subheading, class: 'Tile-subheading')
      end + controls
    end
  end

end
