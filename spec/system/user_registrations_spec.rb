# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "UserRegistrations", type: :system do
  before do
    ActiveJob::Base.queue_adapter = :test
    driven_by(:rack_test)
  end

  context 'Given a brand new user' do
    it 'registers a new user' do
      visit new_user_registration_path
      expect {
        fill_in 'user_email', with: 'alice@example.com'
        fill_in 'user_name', with: 'Alice'
        fill_in 'user_password', with: 'password'
        fill_in 'user_password_confirmation', with: 'password'
        click_button 'commit'
      }.to have_enqueued_mail(UserMailer, :confirmation_instructions)

      expect(page).to have_content 'Thank you for registering'
      expect(page).to have_content 'sent you an email to confirm your account'

      user = User.last
      expect(user).to_not be_confirmed

      token = user.generate_token_for(:confirmation)
      visit user_confirmation_path(token: token)
      expect(page).to have_current_path(new_user_session_path)

      user.reload
      expect(user).to be_confirmed

      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: 'password'
      click_button 'commit'

      expect(page).to have_content 'Sign Out'

    end
  end

  context 'Given an unconfirmed user' do
    let(:user) { create(:user, :unconfirmed) }

    it 'will not sign them in' do
      visit new_user_session_path
      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: 'password'
      click_button 'commit'
      expect(page).to have_content 'You need to confirm your account before signing in'
    end
  end
end
