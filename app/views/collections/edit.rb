# frozen_string_literal: true

class Views::Collections::Edit < Views::Base

  def initialize(collection:, parent_ids:)
    @collection = collection
    @parent_ids = parent_ids
  end

  def view_template
    page_title("Edit #{@collection.name_was || @collection.name}")
    tile_with_heading("Edit Collection") do
      render Views::Collections::Form.new(collection: @collection, parent_ids: @parent_ids)
    end
  end

end
