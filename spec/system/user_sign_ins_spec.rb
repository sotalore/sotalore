# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "UserSignIns", type: :system do
  before do
    driven_by(:rack_test)
  end

  context 'Given a registered user' do
    let!(:user) { create(:user, name: 'Alice', email: 'alice@example.com') }

    it 'allows a user to sign in and out' do
      visit new_user_session_path
      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: 'password'
      click_button 'commit'
      expect(page).to have_content 'Welcome back!'

      expect(page).to have_content 'Sign Out'

      click_link 'Sign Out'
      expect(page).to have_content 'Sign In'
    end
  end
end
