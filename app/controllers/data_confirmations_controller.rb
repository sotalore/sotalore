class DataConfirmationsController < ApplicationController

  before_action :authenticate_user!

  def create
    @parent = find_parent
    authorize(@parent, :update?)
    @parent.update(
      last_confirmed_at: Time.zone.now,
      last_confirmed_by: current_user)
    redirect_to @parent
  end


  private
  def find_parent
    if params[:item_id]
      @parent = Item.find(params[:item_id])
    elsif params[:recipe_id]
      @parent = Recipe.find(params[:recipe_id])
    end
  end

end
