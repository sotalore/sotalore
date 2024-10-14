# frozen_string_literal: true

class Components::Tile < Components::Base

  def initialize(body: nil, heading: nil, subheading: nil, type: nil, options: {})
    @heading = heading
    @subheading = subheading
    @type = type
    @contents = body
    super()
  end

  def view_template
    @contents = capture { yield } if block_given?
    div(class: 'Tile') do
      if @heading
        div(class: 'Tile-heading') do
          h3 do
            plain @heading
            whitespace
            span(class: 'Tile-subheading') { @subheading }
          end
          raw @controls
        end
      end
      div(class: 'Tile-body') do
        raw @contents
      end
    end
  end


  attr_writer :controls
  def controls
    @controls = capture do
      div(class: 'Tile-controls') do
        yield
      end
    end
  end

  attr_writer :contents

end
