# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Authentication::OmniauthCallbacks", type: :request do

  let(:omniauth_data) { double('OmniAuth::AuthHash') }
  let(:omniauth_info) { double('OmniAuth::AuthHash::InfoHash') }
  let(:omniauth_auth) { double('OmniAuth::AuthHash::AuthHash') }

  def set_omniauth(provider:, uid: '12345', email:)
    allow(omniauth_data).to receive(:info).and_return(omniauth_info)
    allow(omniauth_data).to receive(:credentials).and_return(omniauth_auth)

    expect(omniauth_data).to receive(:uid).and_return(uid)
    expect(omniauth_info).to receive(:email).and_return(email)

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[provider] = omniauth_data
  end


  describe "GET /discord/callback" do
    let(:email) { 'alice@example.com' }

    before do
      expect(omniauth_info).to receive(:name).and_return('Alice')
    end

    context 'Given no existing user' do
      it 'creates a new user and signs them in' do
        set_omniauth(provider: :discord, email: email)

        expect { get user_oauth_callback_path(:discord) }
          .to change(User, :count).by(1)

        expect(response).to redirect_to(root_path)
        user = User.last
        expect(user.name).to eq 'Alice'
      end
    end

    context 'Given an existing mismatch account' do
      let!(:user) { create(:user, email: email, provider: 'discord', uid: '987645') }

      it 'leaves them on sign in' do
        set_omniauth(provider: :discord, email: email)
        expect {
          get user_oauth_callback_path(:discord)
        }.to_not change(User, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'Given an existing user matching email, with no discord reference' do
      let!(:user) { create(:user, email: email, provider: 'email', uid: nil) }

      it 'signs them in, and connects User to discord' do
        set_omniauth(provider: :discord, email: email)
        expect {
          get user_oauth_callback_path(:discord)
        }.to_not change(User, :count)
        expect(response).to redirect_to(root_path)

        user.reload
        expect(user.provider).to eq 'discord'
        expect(user.uid).to eq '12345'
      end
    end
  end
end
