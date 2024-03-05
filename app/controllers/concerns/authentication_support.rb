# frozen_string_literal: true

module AuthenticationSupport
  extend ActiveSupport::Concern

  included do
    before_action :set_current_request_details
    before_action :setup_error_reporting_context
    before_action :track_user_activity

    helper_method :current_user
    helper_method :user_signed_in?
  end

  def sign_in_user(user)
    Current.user = user
    user.touch(:last_sign_in_at)
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
    Current.current_user_id = find_current_user_id_with_fallbacks
  end

  def setup_error_reporting_context
    Honeybadger.context({
      user_id: (current_user.null? ? nil : current_user.id),
    })
  end

  def track_user_activity
    return if Current.user.null?

    Current.user.touch(:last_request_at)
  end

  def find_current_user_id_with_fallbacks
    find_current_user_id || find_past_devise_user
  end

  def find_current_user_id
    cookies.signed[:current_user_id]
  end

  # This session management can be removed on April 15
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
        return user.id
      end
    end
    nil
  end

end
