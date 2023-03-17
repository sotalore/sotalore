require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user) }
  before do
    sign_in user
  end

  describe "GET /show" do
    it 'works' do
      get profile_path
      expect(response).to have_http_status(200)
    end
  end
end
