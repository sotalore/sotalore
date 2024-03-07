# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "CommentMigrationPostRegistrations", type: :system do
  before do
    driven_by(:rack_test)
  end

  it 'migrates comments to the new user model after email registration' do
    visit root_path

    fill_in 'comment_body', with: 'This is the test comment'
    click_on 'Post Your Comment'

    expect(page).to have_text('This is the test comment')

    comment = Comment.last
    expect(comment.author).to be_a(NullUser)
    expect(comment.user_key).to be_present

    visit new_user_registration_path
    fill_in 'user_email', with: 'anon-commenter@example.com'
    fill_in 'user_name', with: 'Anon Commenter'
    fill_in 'user_password', with: 'password'
    fill_in 'user_password_confirmation', with: 'password'
    click_on 'commit'

    expect(page).to have_text('Thank you for registering!')

    user = User.last

    expect(comment.reload.author).to be_a(NullUser)
    expect(comment.user_key).to be_present

    visit user_confirmation_path(token: user.generate_token_for(:confirmation))

    user.reload
    expect(user).to be_confirmed

    comment.reload
    expect(comment.author).to eq(user)
    expect(comment.user_key).to be_nil
  end
end
