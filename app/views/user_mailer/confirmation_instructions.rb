# frozen_string_literal: true

class Views::UserMailer::ConfirmationInstructions < Views::Base

  def initialize(user:, token:)
    @user = user
    @token = token
  end

  def view_template
    p { "Hi #{@user.name}," }
    p { "Welcome to SotaLore!" }
    p { "You can activate your account by visiting the link below:" }
    p { link_to("Activate Account", user_confirmation_url(token: @token)) }
  end

end
