# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "UserConfirmations", type: :system do
  include ActiveJob::TestHelper::TestQueueAdapter

  before do
    ActiveJob::Base.queue_adapter = :test
    driven_by(:rack_test)
  end

  let(:user) { create(:user, :unconfirmed) }
  it 'works' do
    visit new_user_confirmation_path
    expect(page).to have_text('Send Confirmation Instructions')

    expect {
      fill_in 'Email', with: user.email
      click_button 'Send Confirmation Instructions'
    }.to have_enqueued_mail(UserMailer, :confirmation_instructions).with(user)
    expect(page).to have_text('Sending Confirmation Email')

    token = user.generate_token_for(:confirmation)
    visit user_confirmation_path(token: token)

    expect(page).to have_text('Your account has been activated, please sign in.')
    expect(page).to have_current_path(new_user_session_path)

    user.reload
    expect(user).to be_confirmed

    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password'
    click_button 'Sign In'
    expect(page).to have_text('Sign Out')
  end
end
