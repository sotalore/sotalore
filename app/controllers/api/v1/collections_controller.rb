# frozen_string_literal: true

# The site's own groupings of items (see Collection): all of them, with how
# they nest, and everything in one.
class Api::V1::CollectionsController < Api::BaseController
  before_action -> { require_scope!('read') }

  # Every collection: there are few, so no paging.
  def index
    authorize(Collection)
    collections = Collection.by_name.includes(:parents, :children, :collection_items)
    render json: { collections: collections.map { collection_summary(_1) } }
  end

  def show
    collection = Collection.find(params[:id])
    authorize(collection)
    render json: collection_detail(collection)
  end
end
