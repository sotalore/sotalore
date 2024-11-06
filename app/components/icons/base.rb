# frozen_string_literal: true

class Components::Icons::Base < Components::Base

  SIZES = {
    xs: 'h-4 w-4',
    sm: 'h-5 w-5',
    md: 'h-6 w-6',
    lg: 'h-12 w-12',
    xl: 'h-24 w-24',
  }.with_indifferent_access.freeze

  COLORS = {
    white: 'text-white',
    gray: 'text-gray-500',
    red: 'text-red-500',
    orange: 'text-orange-500',
    yellow: 'text-yellow-500',
    green: 'text-green-500',
    purple: 'text-purple-500',
    current: 'text-current',
  }.with_indifferent_access.freeze


  def initialize(size: :md, color: :current, **options)
    raise ArgumentError, "Invalid size: #{size}" unless SIZES.key?(size)
    raise ArgumentError, "Invalid color: #{color}" unless COLORS.key?(color)

    @size_class = SIZES[size]
    @color_class = COLORS[color]
    @given_class = options.delete(:class)
  end

  def view_template
    wrapper do
      raw(safe(self.class::MARKUP))
    end
  end

  WRAPPER_CLASSES = 'inline-flex items-center'

  def wrapper(&block)
    span(class: [WRAPPER_CLASSES, @size_class, @color_class, @given_class], &block)
  end

end
