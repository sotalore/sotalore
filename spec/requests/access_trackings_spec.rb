require 'rails_helper'

RSpec.describe "A User accessing the site", type: :request do
  let!(:user) { create(:user) }
  before { sign_in user }
  describe "GET /" do
    it "tracks several things" do
      expect(user.last_request_at).to be_nil
      get root_path
      expect(response).to have_http_status(200)

      expect(user.last_sign_in_at).to be_present
      expect(user.last_request_at).to be_present
    end
  end
end
