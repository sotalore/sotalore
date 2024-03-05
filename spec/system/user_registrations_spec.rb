# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "UserRegistrations", type: :system do
  before do
    driven_by(:rack_test)
  end

  context 'Given a brand new user' do
    it 'registers a new user' do
      visit new_user_registration_path
      fill_in 'user_email', with: 'alice@example.com'
      fill_in 'user_name', with: 'Alice'
      fill_in 'user_password', with: 'password'
      fill_in 'user_password_confirmation', with: 'password'
      click_button 'commit'
      expect(page).to have_content 'Welcome! You have signed up successfully.'
    end
  end
end
