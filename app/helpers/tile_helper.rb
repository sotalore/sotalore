# frozen-string-literal: true

module TileHelper

  def lead_in(&block)
    content_tag(:div, class: "tile-lead-in Tile-leadIn", &block)
  end

  def tile_with_heading(heading, subheading = nil, options={}, &block)
    if Hash === subheading
      options, subheading = subheading, nil
    end
    tile(options[:type]) do
      tile_heading(heading, subheading) +
      tile_body(&block)
    end
  end

  def tile(type=nil, options={}, &block)
    css_class = "#{options[:class]} Tile"
    css_class += " Tile--#{type}" if type
    options[:class] = css_class
    content_tag(:div, options, &block)
  end

  def tile_body(type=nil, &block)
    css_class = "Tile-body"
    css_class += "Tile-body--#{type}" if type
    content_tag(:div, class: css_class, &block)
  end

  def tile_heading(heading, subheading = nil, &block)
    if block_given?
      controls = content_tag(:div, class: "Tile-controls", &block)
    end

    content_tag(:div, class: "Tile-heading") do
      content_tag(:h3) do
        content_tag(:span, heading) + ' ' +
          content_tag(:span, subheading, class: 'Tile-subheading')
      end + controls
    end
  end

end
