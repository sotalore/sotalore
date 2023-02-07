# frozen-string-literal: true

module LayoutHelper
  def entire_page
    content_tag(:div, class: 'row mx-2') do
      content_tag(:div, class: 'col-xs-12') do
        yield
      end
    end
  end

  def single_column
    content_tag(:div, class: 'grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4') do
      content_tag(:div, class: 'col-span-2') do
        yield
      end
    end
  end
  alias_method :single_wide_column, :single_column
  alias_method :single_centered_column, :single_column

end
