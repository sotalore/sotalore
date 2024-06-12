# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Authentication::Sessions", type: :request do

  describe "GET /new" do
    it "is successful" do
      get new_user_session_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    let!(:user) { create(:user, email: 'alice@example.com', password: 'password') }

    it 'signs-in the user' do
      post user_session_path, params: { user: { email: user.email, password: 'password' } }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('Welcome back!')
    end

    context 'Given wrong credentials' do
      it 'does not sign-in the user' do
        post user_session_path, params: { user: { email: user.email, password: 'wrong' } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('That email or password is incorrect')
      end
    end
  end

  describe "DELETE /destroy" do
    it 'signs-out the user' do
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)
    end
  end

  context 'Given a signed-in user' do
    let!(:user) { create(:user, email: 'alice@example.com', password: 'password') }

    before do
      post user_session_path, params: { user: { email: user.email, password: 'password' } }
    end

    describe "GET /new" do
      it 'redirects to root_path' do
        get new_user_session_path
        expect(response).to redirect_to(root_path)
      end
    end

    describe "POST /create" do
      it 'redirects to root_path' do
        post user_session_path, params: { user: { email: user.email, password: 'password' } }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
