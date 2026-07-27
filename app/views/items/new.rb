# frozen_string_literal: true

class Views::Items::New < Views::Items::Base

  def initialize(item:)
    @item = item
  end

  def view_template
    tile_with_heading("Add New Item") do
      render Views::Items::Form.new(item: @item)
    end
  end

end
