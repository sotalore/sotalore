# frozen_string_literal: true

# frozen_string_literal: true

class Views::Base < Components::Base
  # The ApplicationView is an abstract class for all your views.

  # By default, it inherits from `ApplicationComponent`, but you
  # can change that to `Phlex::HTML` if you want to keep views and
  # components independent.

  MAIN_CONTENT_SIZE_CLASSES = {
    sm: 'max-w-screen-sm',
    md: 'max-w-screen-md',
    lg: 'max-w-screen-lg',
    xl: 'max-w-screen-xl',
    full: 'max-w-full',
  }

  def paginate(collection, window: 4)
    render Components::Pagination.new(collection, window: window)
  end

  def layout_main_content(size: :md, centered: false)
    raise ArgumentError, "Invalid size: #{size}" unless MAIN_CONTENT_SIZE_CLASSES.key?(size)

    classes = [ MAIN_CONTENT_SIZE_CLASSES[size], "mx-2 my-4" ]
    classes << 'mx-auto' if centered

    div(class: classes.join(" ")) { yield }
  end
end
