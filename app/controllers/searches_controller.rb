class SearchesController < ApplicationController
  skip_after_action :verify_authorized

  def show
    @searches = PgSearch.multisearch(params[:q])
                .includes(:searchable)
                .where(searchable_type: 'Item')
                .page(params[:page])
    respond_to do |format|
      format.html { }
      format.json { render json: render_global_response_for_autocomplete(@searches) }
    end
  end

  def items
    query = params[:query]
    if query.blank? || query.length < 3
      results = []
    else
      results = PgSearch.multisearch(query)
                .includes(:searchable)
                .where(searchable_type: 'Item')
    end
    render json: response_for_autocomplete(results)
  end

  private
  def render_global_response_for_autocomplete(results)
    {
      suggestions: results.map { |r|
        name = "#{r.searchable.name}"
        url  = url_for(r.searchable)
        { value: name, data: url }
      }
    }.to_json
  end

  def response_for_autocomplete(results)
    {
      suggestions: results.map { |i| { value: i.searchable.name, data: i.searchable.id } }
    }.to_json
  end
end
