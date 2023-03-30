require 'rails_helper'

RSpec.describe "Avatars", type: :request do

  let(:user)    { create :user }
  before        { sign_in user }

  describe 'request list of all avatars' do
    it 'shows the avatars' do
      avatar = Avatar.create!(user: user, name: 'FooBar Baz')
      get avatars_path
      expect(response).to be_successful
      expect(response.body).to include('FooBar Baz')
    end

    it 'shows a message when there are no avatars' do
      get avatars_path
      expect(response).to be_successful
      expect(response.body).to include('add one below')
    end
  end

  describe 'create an avatar' do
    it 'works' do
      post avatars_path, params: { avatar: { name: 'Jack' }}
      expect(response).to redirect_to(avatars_path)
    end
  end

  describe 'request edit form for avatar' do
    it 'works' do
      avatar = Avatar.create!(user: user, name: 'FooBar Baz')
      get edit_avatar_path(avatar)
      expect(response).to be_successful
    end
  end

  describe 'upddating an avatar' do
    it 'works' do
      avatar = Avatar.create!(user: user, name: 'FooBar Baz')
      patch avatar_path(avatar), params: { avatar: { name: 'New Name' }}
      expect(response).to redirect_to(avatars_path)
      avatar.reload
      expect(avatar.name).to eq 'New Name'
    end

    it 'works' do
      avatar = Avatar.create!(user: user, name: 'FooBar Baz')
      patch avatar_path(avatar), params: { avatar: { name: ' ' }}
    end
  end

  describe 'destroying an avatar' do
    it 'works' do
      avatar = Avatar.create!(user: user, name: 'FooBar Baz')
      delete avatar_path(avatar)
      expect(response).to redirect_to(avatars_path)

      expect(Avatar.find_by_id(avatar.id)).to eq nil
    end
  end
end
