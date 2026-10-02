class AbstractionsController < ApplicationController

  def index
    items = Item.abstract.order(:kind).by_name
    items = items.includes(:members).page(params[:page]).per(200)
    authorize Item
    render Views::Abstractions::Index.new(items: items)
  end

end
