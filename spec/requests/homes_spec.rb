require 'rails_helper'

RSpec.describe "HomeController", type: :request do
  before do
    create(:recipe)
  end
  describe "GET /show" do
    it "works! (now write some real specs)" do
      get root_path
      expect(response).to have_http_status(200)
    end
  end
end
