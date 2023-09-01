# frozen-string-literal: true

module LayoutHelper

  SIZE_CLASSES = {
    sm: 'max-w-screen-sm',
    md: 'max-w-screen-md',
    lg: 'max-w-screen-lg',
    xl: 'max-w-screen-xl'
  }

  def layout_main_content(size: :md, centered: false)
    raise ArgumentError, "Invalid size: #{size}" unless SIZE_CLASSES.key?(size)

    classes = [SIZE_CLASSES[size], "m-4"]
    classes << 'mx-auto' if centered

    content_tag(:div, class: classes.join(" ")) do
      yield
    end
  end

end
