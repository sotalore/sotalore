# frozen_string_literal: true

module AuthenticationSupport
  extend ActiveSupport::Concern

  included do
    before_action :set_current_request_details
    before_action :setup_error_reporting_context
    before_action :track_user_activity

    helper_method :user_signed_in?
  end

  def sign_in_user(user)
    Current.user = user
    user.update!(
      last_sign_in_ip: Current.ip_address,
      last_sign_in_at: Time.current,
      sign_in_count: user.sign_in_count + 1,
      last_request_at: Time.current)
    cookies.signed.permanent[:current_user_id] = { value: user.id, httponly: true }
  end

  def sign_out_user
    cookies.delete(:current_user_id)
    Current.user = NullUser.new
  end

  def user_signed_in?
    Current.user.not_null?
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
    Current.user = find_current_user
  end

  def setup_error_reporting_context
    Honeybadger.context({
      user_id: (Current.user.null? ? nil : Current.user.id),
    })
  end

  def track_user_activity
    return if Current.user.null?

    Current.user.touch(:last_request_at)
  end

  def find_current_user
    User.find_by(id: cookies.signed[:current_user_id])
  end

end
