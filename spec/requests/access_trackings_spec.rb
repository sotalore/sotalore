require 'rails_helper'

RSpec.describe "A User accessing the site", type: :request do
  let!(:user) { create(:user) }

  describe "GET /" do
    it "tracks several things" do
      expect(user.last_request_at).to be_nil

      post user_session_path params: { user: { email: user.email, password: 'password' } }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response).to have_http_status(200)

      user.reload
      expect(user.last_sign_in_at).to be_present
      expect(user.last_request_at).to be_present
    end
  end
end
