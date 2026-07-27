# frozen_string_literal: true

module PaginationHelper

  def phlex_paginate(collection, window: 4)
    render Components::Pagination.new(collection, window: window)
  end

end
