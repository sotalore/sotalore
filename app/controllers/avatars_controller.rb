class AvatarsController < ApplicationController

  before_action     :authenticate_user!, except: [ :index ]
  skip_after_action :verify_authorized

  def index
    find_avatars if Current.user.not_null?
    render Views::Avatars::Index.new(avatars: @avatars)
  end

  def create
    @avatar = Current.user.avatars.new(permitted_params)
    if @avatar.save
      redirect_to action: :index
    else
      find_avatars
      render Views::Avatars::Index.new(avatars: @avatars, avatar: @avatar), status: :unprocessable_content
    end
  end

  def edit
    @avatar = Current.user.avatars.find(params[:id])
    render Views::Avatars::Edit.new(avatar: @avatar)
  end

  def update
    @avatar = Current.user.avatars.find(params[:id])
    if @avatar.update(permitted_params)
      redirect_to action: :index
    else
      render Views::Avatars::Edit.new(avatar: @avatar), status: :unprocessable_content
    end
  end

  def destroy
    @avatar = Current.user.avatars.find(params[:id])
    @avatar.destroy
    redirect_to action: :index
  end

  private

  def find_avatars
    @avatars = Current.user.avatars
    if @avatars.empty?
      @avatars = nil
    end
  end

  def permitted_params
    params.require(:avatar).permit(:name, :is_default)
  end
end
