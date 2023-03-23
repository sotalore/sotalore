# frozen-string-literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include Pundit::Authorization

  after_action :verify_authorized, unless: -> { in_active_admin? }
  after_action :record_last_request_at

  if Rails.env.production?
    before_action :redirect_herokuapp_url
  end

  before_action :set_anonymous_user_key

  protected

  def page_title(text=:not_provided)
    unless text == :not_provided
      request.env['page_title'] = text
    end
    request.env['page_title']
  end
  helper_method :page_title

  def current_user
    super || (@_null_user ||= NullUser.new)
  end


  def set_anonymous_user_key
    if current_user.null?
      if cookies[:user_key].nil?
        current_user.user_key = cookies[:user_key] = SecureRandom.hex(24)
      else
        current_user.user_key = cookies[:user_key]
      end
    end
  end

  def in_active_admin?
    self.is_a?(ActiveAdmin::BaseController)
  end

  def unauthorized_admin_access(*args)
    redirect_to root_url
  end

  def record_last_request_at
    return if current_user.null?
    current_user.update(last_request_at: Time.now)
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
