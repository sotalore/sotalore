class AbstractionsController < ApplicationController
  
  def index
    @items = Item.where(abstract: true).by_name
    if params.key?(:unconfirmed)
      @items = @items.where(last_confirmed_at: nil)
    end
    @items = @items.by_name.page(params[:page]).per(200)
    authorize Item
  end

end
