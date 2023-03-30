require 'rails_helper'

RSpec.describe "Searches", type: :request do
  let!(:item) { Item.create(name: 'Test Fake Item') }

  describe 'GET items' do
    it 'works' do
      get search_items_path, params: { q: 'fake' }
      expect(response.body).to include(item.name)
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:items)
    end
  end

  describe 'GET global' do
    it 'works' do
      get search_global_path, params: { q: 'fake' }
      expect(response.body).to include(item.name)
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:global)
    end
  end

  describe 'GET show' do
    it 'works' do
      get search_path, params: { q: 'fake' }
      expect(response.body).to include(item.name)
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
    end
  end

end
