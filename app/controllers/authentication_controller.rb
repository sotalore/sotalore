# frozen_string_literal: true

class AuthenticationController < ApplicationController
  skip_after_action :verify_authorized

  private

  def redirect_signed_in_user
    redirect_to root_path if user_signed_in?
  end

end
