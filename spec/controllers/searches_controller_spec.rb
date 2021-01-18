require 'rails_helper'

RSpec.describe SearchesController, type: :controller do
  render_views

  describe 'GET items' do
    let!(:item) { Item.create(name: 'Test Fake Item') }
    it 'works' do
      get :items, params: { q: 'fake' }
      expect(response.body).to include(item.name)
    end
  end

end

