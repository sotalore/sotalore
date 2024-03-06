# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "UserPasswordResets", type: :system do
  before do
    ActiveJob::Base.queue_adapter = :test
    driven_by(:rack_test)
  end

  it 'successfully resets password' do
    user = create(:user)

    visit new_user_session_path
    click_link 'Forgot your password?'

    expect {
      fill_in 'Email', with: user.email
      click_button 'Send Password Reset Instructions'
    }.to have_enqueued_mail(UserMailer, :password_reset).with(user)

    expect(page).to have_content("We've sent you an email to reset the password on your account.")

    visit edit_user_password_reset_path(token: user.generate_token_for(:password_reset))

    # mimic an error, with a bad password
    fill_in 'user[password]', with: 'newpassword'
    fill_in 'user[password_confirmation]', with: 'wrong'
    click_button 'Change Password'

    expect(page).to have_content("doesn't match Password")

    fill_in 'user[password]', with: 'newpassword'
    fill_in 'user[password_confirmation]', with: 'newpassword'
    click_button 'Change Password'

    expect(page).to have_current_path(root_path)
    expect(page).to have_content('Sign Out')

    click_link 'Sign Out'
    click_link 'Sign In'
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'newpassword'
    click_button 'Sign In'

    expect(page).to have_content('Sign Out')
  end
end
