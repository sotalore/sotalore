class SearchesController < ApplicationController
  skip_after_action :verify_authorized

  layout false, only: [ :global, :items ]

  def show
    @searches = PgSearch.multisearch(params[:q])
                .includes(:searchable)
                .where(searchable_type: 'Item')
                .page(params[:page])
  end

  def global
    @searches = PgSearch.multisearch(params[:q])
                .includes(:searchable)
                .where(searchable_type: 'Item')
                .page(params[:page])
  end

  def items
    query = params[:q]
    if query.blank? || query.length < 3
      @searches = []
    else
      @searches = PgSearch.multisearch(query)
                .includes(:searchable)
                .where(searchable_type: 'Item')
    end
  end

end
