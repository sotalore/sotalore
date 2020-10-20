class AbstractionsController < ApplicationController

  def index
    @items = Item.where(abstract: true).by_name
    @items = @items.by_name.page(params[:page]).per(200)
    authorize Item
  end

end
