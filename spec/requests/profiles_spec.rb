require 'rails_helper'

RSpec.describe "Profiles", type: :request do

  context 'Given a regular user' do
    let(:user) { create :user }
    before { sign_in user }

    describe 'GET show' do
      it 'works' do
        get profile_path
        expect(response).to be_successful
      end
    end

    describe 'PATCH update' do
      it 'works' do
        patch profile_path, params: {user: {name: 'new name'}}
        expect(response).to redirect_to(profile_path)
        expect(user.reload.name).to eq 'new name'
      end

      it 'handles invalid attributes' do
        patch profile_path, params: {user: {name: ''}}
        expect(response).to have_http_status(:unprocessable_entity)
      end

    end
  end
end
