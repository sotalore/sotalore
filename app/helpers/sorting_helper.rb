# frozen_string_literal: true

module SortingHelper

  def sort_link(name, field)
    path = request.path
    asc_val = "#{field}_asc"
    desc_val = "#{field}_desc"
    if request.params[:sort] == asc_val
      path = "#{path}?sort=#{desc_val}"
      name = decorate_sort_link_up(name)
    elsif request.params[:sort] == desc_val
      path = "#{path}?sort=#{asc_val}"
      name = decorate_sort_link_down(name)
    else
      path = "#{path}?sort=#{asc_val}"
    end
    link_to name, path, class: 'text-inherit underline'
  end

  def decorate_sort_link_up(name)
    content_tag(:span, "#{h name}&nbsp;&#8963;".html_safe, class: 'bold')
  end

  def decorate_sort_link_down(name)
    content_tag(:span, "#{h name}&nbsp;&#8964;".html_safe, class: 'bold')
  end

  ALLOWED_DIRECTIONS = %w[asc desc].freeze

  def get_sort_field_and_direction(allowed, default, direction='asc')
    current = request.params[:sort]
    if current.present?
      field, _, dir = current.rpartition('_')
      unless allowed.include?(field)
        field = default
        dir = direction
      end
    else
      field = default
      dir = direction
    end
    dir = direction unless ALLOWED_DIRECTIONS.include?(dir)
    request.params[:sort] = "#{field}_#{dir}"
    [field, dir]
  end
end
