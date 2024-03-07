# frozen-string-literal: true

class ApplicationController < ActionController::Base
  include AuthenticationSupport
  include Pundit::Authorization
  protect_from_forgery with: :exception

  after_action :verify_authorized
  after_action :record_last_request_at

  if Rails.env.production?
    before_action :redirect_herokuapp_url
  end

  before_action :set_anonymous_user_key

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def page_title(text=:not_provided)
    unless text == :not_provided
      request.env['page_title'] = text
    end
    request.env['page_title']
  end
  helper_method :page_title

  def set_anonymous_user_key
    if current_user.null?
      if cookies[:user_key].nil?
        Current.user_key = cookies[:user_key] = SecureRandom.hex(24)
      else
        Current.user_key = cookies[:user_key]
      end
    end
  end

  def record_last_request_at
    return if current_user.null?
    current_user.update_attribute(:last_request_at, Time.now)
  end

  def user_not_authorized(exception)
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to root_path
  end

  private

  NEW_NAME_MESSAGE = "We've come up with a better name. We're now SotA Lore.
We have a new URL to reflect that, we're now at: www.sotalore.com"
  def redirect_herokuapp_url
    if request.host != 'www.sotalore.com'
      flash[:notice] = NEW_NAME_MESSAGE
      redirect_to "https://www.sotalore.com#{request.original_fullpath}"
    end

  end
end
