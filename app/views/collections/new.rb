# frozen_string_literal: true

class Views::Collections::New < Views::Base

  def initialize(collection:, parent_ids:)
    @collection = collection
    @parent_ids = parent_ids
  end

  def view_template
    page_title("New Collection")
    tile_with_heading("New Collection") do
      render Views::Collections::Form.new(collection: @collection, parent_ids: @parent_ids)
    end
  end

end
