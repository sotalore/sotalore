class AvatarsController < ApplicationController

  before_action     :authenticate_user!, except: [ :index ]
  skip_after_action :verify_authorized

  def index
    find_avatars if current_user.not_null?
  end

  def create
    @avatar = current_user.avatars.new(permitted_params)
    if @avatar.save
      redirect_to action: :index
    else
      find_avatars
      render :index
    end
  end

  def edit
    @avatar = current_user.avatars.find(params[:id])
  end

  def update
    @avatar = current_user.avatars.find(params[:id])
    if @avatar.update(permitted_params)
      redirect_to action: :index
    else
      render :edit
    end
  end

  def destroy
    @avatar = current_user.avatars.find(params[:id])
    @avatar.destroy
    redirect_to action: :index
  end

  private

  def find_avatars
    @avatars = current_user.avatars
    if @avatars.empty?
      @avatars = nil
    end
  end

  def permitted_params
    params.require(:avatar).permit(:name, :is_default)
  end
end
