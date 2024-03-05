# frozen_string_literal: true

class Authentication::OmniauthCallbacksController < ApplicationController
  skip_after_action :verify_authorized

  def callback
    auth_params = from_discord_params
    user = User.from_discord(**auth_params)

    provider = params[:provider]
    provider_name = t("auth.providers.#{provider}")

    if user.present?
      sign_in_user user
      flash[:success] = t 'auth.oauth.success', kind: provider_name
      redirect_to after_sign_in_path
    else
      flash[:alert] = t 'auth.oauth.failure', kind: provider_name, reason: "Your email is already associated with an account."
      redirect_to new_user_session_path
    end
  end

  protected

  def after_sign_in_path
    stored_location_for_user || root_path
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
