# frozen-string-literal: true

class PlantingsController < ApplicationController

  before_action     :authenticate_user!
  skip_after_action :verify_authorized


  def index
    find_plantings
  end

  def create
    @planting = current_user.plantings.build(permitted_params)
    if @planting.save
      flash.notice = 'Added planting'
      redirect_to action: :index
    else
      find_plantings
      render :index
    end
  end

  def destroy
    find_planting
    @planting.destroy
    redirect_to action: :index
  end

  private
  def find_plantings
    @plantings = current_user.plantings.order(planted_at: :desc).page(params[:page])
  end

  def find_planting
    @planting = current_user.plantings.find(params[:id])
  end

  def permitted_params
    params.require(:planting).permit(
      :seed_id, :location_type, :planted_at, :notes)
  end
end
