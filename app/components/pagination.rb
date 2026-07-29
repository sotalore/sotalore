# frozen_string_literal: true

# Renders pagination links for a Kaminari-paginated collection, driven entirely
# by the collection's own API (current_page/total_pages/first_page?/last_page?)
# rather than Kaminari's ActionView helpers/theme partials.
class Components::Pagination < Components::Base

  register_value_helper :url_for
  register_value_helper :t

  EXCLUDED_PARAM_KEYS = %i[authenticity_token commit utf8 _method script_name original_script_name].freeze

  def initialize(collection, window: 4)
    @collection = collection
    @window = window
  end

  def view_template
    return if @collection.total_pages <= 1

    ul(class: "Pagination") do
      edge_item(:first, page: 1) unless @collection.first_page?
      edge_item(:previous, page: @collection.current_page - 1, rel: "prev") unless @collection.first_page?

      page_numbers.each { |page| number_item(page) }

      edge_item(:next, page: @collection.current_page + 1, rel: "next") unless @collection.last_page?
      edge_item(:last, page: @collection.total_pages) unless @collection.last_page?
    end
  end

  private

  # The current page, plus a window of pages either side of it.
  def page_numbers
    total = @collection.total_pages
    current = @collection.current_page
    low = [ current - @window, 1 ].max
    high = [ current + @window, total ].min
    (low..high).to_a
  end

  def number_item(page)
    if page == :gap
      li(class: "Pagination-page") { a { entity(:truncate) } }
    elsif page == @collection.current_page
      li(class: "Pagination-page is-active") { a { plain page.to_s } }
    else
      li(class: "Pagination-page") { a(href: page_url(page)) { plain page.to_s } }
    end
  end

  def edge_item(key, page:, rel: nil)
    li(class: "Pagination-page") do
      a(href: page_url(page), rel: rel) { entity(key) }
    end
  end

  def entity(key)
    raw(safe(t("views.pagination.#{key}")))
  end

  def page_url(page)
    query = params.to_unsafe_h.with_indifferent_access.except(*EXCLUDED_PARAM_KEYS)
    if page > 1
      query[:page] = page
    else
      query.delete(:page)
    end
    url_for(query.merge(only_path: true))
  end

end
