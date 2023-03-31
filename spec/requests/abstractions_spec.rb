require 'rails_helper'

RSpec.describe "Abstractions", type: :request do
  describe "GET /abstractions" do
    let(:item) { create :item, abstract: true }
    it "works" do
      get abstractions_path
      expect(response).to have_http_status(200)
    end
  end
end
