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
    content_tag(:div, class: 'row') do
      content_tag(:div, class: 'col-xs-12 col-md-8 col-lg-6') do
        yield
      end
    end
  end
  alias_method :single_wide_column, :single_column
  alias_method :single_centered_column, :single_column

end
