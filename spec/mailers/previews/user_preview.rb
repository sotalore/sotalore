# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/user
class UserPreview < ActionMailer::Preview

  def confirmation_instructions
    UserMailer.confirmation_instructions(User.first)
  end

  def password_reset
    UserMailer.password_reset(User.first)
  end

end
