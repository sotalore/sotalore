require 'rails_helper'

RSpec.describe ItemsController, type: :controller do
  render_views

  let!(:item) { create :item, use: 'food' }

  describe 'GET index' do
    it 'works' do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET by_use' do
    it 'works' do
      get :by_use, params: { use: 'food' }
      expect(response).to have_http_status(:ok)
    end
  end
end