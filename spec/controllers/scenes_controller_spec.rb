require 'rails_helper'

RSpec.describe ScenesController, type: :controller do

  let!(:scene) { create :scene }
  let!(:user)  { create :user, :root }
  before       { sign_in user }

  describe 'GET index' do
    it 'works' do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET new' do
    it 'works' do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST create' do
    it 'adds a scene' do
      expect {
        post :create, params: { scene: { name: 'Foo Bar', parent_id: scene.id } }
      }.to change { Scene.count }.by(1)
      expect(response).to redirect_to action: :new
    end

    it 'handles invalid params' do
      post :create, params: { scene: { name: '', parent_id: scene.id } }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET show' do
    it 'works' do
      get :show, params: { id: scene }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET edit' do
    it 'works' do
      get :edit, params: { id: scene }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST update' do
    it 'updates the scene' do
      patch :update, params: { id: scene, scene: { name: 'New Name' } }
      expect(scene.reload.name).to eq 'New Name'
      expect(response).to redirect_to scene
    end

    it 'handles invalid params' do
      patch :update, params: { id: scene, scene: { name: '' } }
      expect(response).to have_http_status(:ok)
    end
  end

end
