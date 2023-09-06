# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users::OmniauthCallbacks", type: :request do

  class DiscordOauthData
    attr_accessor :uid, :name, :email
    def provider; 'discord'; end
    def info; self; end
  end

  def set_omniauth(provider:)
    OmniAuth.config.test_mode = true

    oauth_data = DiscordOauthData.new
    oauth_data.uid = '12345'
    oauth_data.name = 'Foo Bar'
    oauth_data.email = 'foo@example.com'

    OmniAuth.config.mock_auth[provider] = oauth_data
  end

  describe "GET /index" do
    context 'Given no existing user' do
      it 'creates a new user and signs them in' do
        set_omniauth(provider: :discord)
        expect {
          get user_discord_omniauth_callback_path
        }.to change(User, :count).by(1)
        expect(response).to redirect_to(root_path)

        user = User.last
        expect(user.name).to eq 'Foo Bar'
      end
    end

    context 'Given an existing mismatch account' do
      let!(:user) { create(:user, email: 'foo@example.com', provider: 'discord', uid: '987645') }

      it 'leaves them on sign in' do
        set_omniauth(provider: :discord)
        expect {
          get user_discord_omniauth_callback_path
        }.to_not change(User, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'Given an existing user matching email, with no discord reference' do
      let!(:user) { create(:user, email: 'foo@example.com', provider: 'email', uid: nil) }

      it 'signs them in, and connects User to discord' do
        set_omniauth(provider: :discord)
        expect {
          get user_discord_omniauth_callback_path
        }.to_not change(User, :count)
        expect(response).to redirect_to(root_path)

        user.reload
        expect(user.provider).to eq 'discord'
        expect(user.uid).to eq '12345'
      end
    end
  end
end
