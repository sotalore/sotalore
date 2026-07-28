# frozen_string_literal: true

class UserMailer < ApplicationMailer

  def confirmation_instructions(user)
    @user = user
    @token = user.generate_token_for(:confirmation)
    mail(to: user.email, subject: 'Confirm Your SotaLore Account!') do |format|
      format.text
      format.html { render Views::UserMailer::ConfirmationInstructions.new(user: user, token: @token) }
    end
  end

  def password_reset(user)
    @user = user
    #ensure the user has a password, otherwise generate a random one
    if user.password_salt.blank?
      user.password = SecureRandom.hex(20)
      user.save(validate: false) # Skip validations to avoid issues with password requirements
    end
    @token = user.generate_token_for(:password_reset)
    mail(to: user.email, subject: 'Reset Your SotaLore Password') do |format|
      format.text
      format.html { render Views::UserMailer::PasswordReset.new(user: user, token: @token) }
    end
  end

end
