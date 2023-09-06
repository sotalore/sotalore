# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

 def discord
    user = User.from_discord(**from_discord_params)

    if user.present?
      sign_out_all_scopes
      flash[:success] = t 'devise.omniauth_callbacks.success', kind: 'Discord'
      sign_in_and_redirect user, event: :authentication
    else
      flash[:alert] = t 'devise.omniauth_callbacks.failure', kind: 'Discord', reason: "#{auth.info.email} is already associated with an account."
      redirect_to new_user_session_path
    end
  end

  protected

  def after_omniauth_failure_path_for(_scope)
    new_user_session_path
  end

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || root_path
  end

  private

  def from_discord_params
    @from_discord_params ||= {
      uid: auth.uid,
      email: auth.info.email,
      name: auth.info.name,
    }
  end

  def auth
    @auth ||= request.env['omniauth.auth']
  end
end
