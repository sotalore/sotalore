# frozen_string_literal: true

class Views::Items::Edit < Views::Items::Base

  def initialize(item:)
    @item = item
  end

  def view_template
    tile_with_heading("Edit Item") do
      render Views::Items::Form.new(item: @item)
    end
  end

end
