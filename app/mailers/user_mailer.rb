# frozen_string_literal: true

class UserMailer < ApplicationMailer

  def confirmation_instructions(user)
    @user = user
    @token = user.generate_token_for(:confirmation)
    mail(to: user.email, subject: 'Confirm Your SotaLore Account!')
  end


end
