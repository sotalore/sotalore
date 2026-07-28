# frozen_string_literal: true

class Views::UserMailer::PasswordReset < Views::Base

  def initialize(user:, token:)
    @user = user
    @token = token
  end

  def view_template
    p { "Hi #{@user.name}," }
    p { "You can reset your password for SotaLore by following the link below:" }
    p { link_to("Reset Your Password", edit_user_password_reset_url(token: @token)) }
    p { "If you didn't request to reset your password, you can safely ignore this email." }
  end

end
