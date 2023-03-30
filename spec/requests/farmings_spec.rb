require 'rails_helper'

RSpec.describe "Farmings", type: :request do
  describe "GET #show" do
    it "returns http success" do
      get farming_path
      expect(response).to have_http_status(:ok)
    end
  end
end
