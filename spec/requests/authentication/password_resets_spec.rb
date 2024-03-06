# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Authentication::PasswordResets", type: :request do
  describe "GET /new" do
    it 'works' do
      get new_user_password_reset_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /create' do
    context 'Given a valid email' do
      let(:user) { create(:user) }
      it 'works' do
        clear_enqueued_jobs

        expect {
          post user_password_reset_path, params: { user: { email: user.email } }
        }.to have_enqueued_mail(UserMailer, :password_reset).with(user)

        expect(response).to redirect_to(user_password_reset_path)
      end
    end

    context 'Given an invalid email' do
      it 'renders the error' do
        post user_password_reset_path, params: { user: { email: 'invalid' } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /edit' do
    context 'Given a valid token' do
      let(:user) { create(:user) }
      it 'works' do
        get edit_user_password_reset_path(token: user.generate_token_for(:password_reset))

        expect(response).to have_http_status(:success)
      end
    end

    context 'Given an invalid token' do
      it 'redirects to the new password reset page' do
        get edit_user_password_reset_path(token: 'invalid')

        expect(response).to redirect_to(new_user_password_reset_path)
      end
    end
  end

  describe 'PATCH /update' do
    context 'Given a valid token and new-password' do
      let(:user) { create(:user) }
      it 'works' do
        patch user_password_reset_path(token: user.generate_token_for(:password_reset)), params: {
          user: { password: 'new_password', password_confirmation: 'new_password' } }

        expect(response).to redirect_to(root_path)
      end
    end

    context 'Given a valid token and invalid new-password' do
      let(:user) { create(:user) }
      it 'works' do
        patch user_password_reset_path(token: user.generate_token_for(:password_reset)), params: {
          user: { password: 'pass', password_confirmation: 'pass' } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'Given an invalid token' do
      it 'redirects to the new password reset page' do
        patch user_password_reset_path(token: 'invalid'), params: { user: { password: 'new_password' } }

        expect(response).to redirect_to(new_user_password_reset_path)
      end
    end
  end
end
