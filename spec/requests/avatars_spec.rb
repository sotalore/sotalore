require 'rails_helper'

RSpec.describe "Avatars", type: :request do

  context 'Given a regular user' do
    let(:user) { create :user }
    before { sign_in user }

    it_behaves_like 'an editable resource', except: [:new, :show] do
      let(:fixture) { [:avatar, {user: user}] }
      let(:model) { Avatar}
      let(:invalid_attributes) { {name: ''} }
      let(:redirect_to_after_create) { avatars_path }
      let(:redirect_to_after_update) { avatars_path }
    end

    describe 'request list of all avatars' do
      it 'shows a message when there are no avatars' do
        get avatars_path
        expect(response).to be_successful
        expect(response.body).to include('add one below')
      end
    end

  end

  context 'Given a regular user and another user avatar' do
    let(:user) { create :user }
    before { sign_in user }

    let(:avatar) { create :avatar }

    describe 'PATCH update' do
      it 'forbids access to update' do
        patch avatar_path(avatar), params: {avatar: {name: 'new name'}}

        expect(response).to have_http_status(:not_found)
      end
    end

  end

end
