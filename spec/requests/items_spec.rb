require 'rails_helper'

RSpec.describe "Items", type: :request do
  let(:current_user) { create :user, :root }
  before { sign_in current_user }

  it_behaves_like "a standard root-only editable resource" do
    let(:model) { Item }
    let(:fixture) { :item }
    let(:invalid_attributes) { { name: '' } }
  end

  describe 'GET by_use' do
    it 'works' do
      get by_use_items_path(use: 'food')
      expect(response).to have_http_status(:ok)
    end
  end

end
