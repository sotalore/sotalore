require 'rails_helper'

RSpec.describe "Items", type: :request do

  context 'Given current_user is root' do
    let(:current_user) { create :user, :root }
    before { sign_in current_user }

    it_behaves_like "an editable resource" do
      let(:model) { Item }
      let(:fixture) { :item }
      let(:invalid_attributes) { { name: '' } }
    end
  end

  context 'Given current_user is a regular user' do
    let(:current_user) { create :user }
    before { sign_in current_user }

    it_behaves_like "a non-editable resource" do
      let(:model) { Item }
      let(:fixture) { :item }
    end
  end

  describe 'GET by_use' do
    it 'works' do
      get by_use_items_path(use: 'food')
      expect(response).to have_http_status(:ok)
    end
  end

end
