# frozen_string_literal: true

module AuthenticationSupport
  extend ActiveSupport::Concern

  included do
    before_action :set_current_request_details
    before_action :setup_error_reporting_context

    helper_method :current_user
    helper_method :user_signed_in?
  end

  def sign_in_user(user)
    cookies.signed.permanent[:current_user_id] = { value: user.id, httponly: true }
  end

  def sign_out_user
    cookies.delete(:current_user_id)
    Current.user = NullUser.new
  end

  def current_user
    Current.user ||= find_user_with_fallbacks
  end

  def user_signed_in?
    current_user && current_user.not_null?
  end

  def authenticate_user!
    unless user_signed_in?
      store_location_for_user(request.fullpath)
      redirect_to new_user_session_path, alert: "You need to sign in or sign up before continuing."
    end
  end

  def store_location_for_user(location)
    session["user_return_to"] = location
  end

  def stored_location_for_user
    session.delete("user_return_to")
  end

  private

  def set_current_request_details
    Current.user_agent = request.user_agent
    Current.ip_address = request.remote_ip
    Current.user = current_user
  end

  def setup_error_reporting_context
    Honeybadger.context({
      user_id: (current_user.null? ? nil : current_user.id),
    })
  end

  def find_user_with_fallbacks
    find_current_user || find_past_devise_user || NullUser.new
  end

  def find_current_user
    (cookies[:current_user_id] && User.find_by(id: cookies[:current_user_id]))
  end

  # This session management can be removed on March 15.
  # That will give about 1 month for users to transfer their sessions
  # from devise to the newer session management.
  def find_past_devise_user
    warden_info = session['warden.user.user.key']
    session.delete('warden.user.user.key')
    if warden_info && warden_info.is_a?(Array)
      user_id, salt = warden_info
      user_id = user_id.first if user_id.is_a?(Array)
      user = User.find_by(id: user_id)

      if user && user.encrypted_password[0,29] == salt
        sign_in_user(user)
        return user
      end
    end
    nil
  end

end
