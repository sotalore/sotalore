require 'rails_helper'

RSpec.describe "Styles", type: :request do
  let(:user) { create(:user, :root) }
  describe "GET /show" do
    it 'works' do
      sign_in user
      get styles_path(user)
      expect(response).to have_http_status(200)
    end
  end
end
