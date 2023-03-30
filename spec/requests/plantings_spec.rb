require 'rails_helper'

RSpec.describe "Plantings", type: :request do
  let!(:current_user) { create :user }
  before { sign_in current_user }

  let!(:seed) { create :item, :seed }

  describe "GET /plantings" do
    let!(:planting) { create :planting, user: current_user, planted_at: 1.day.ago, seed: seed }
    it "works" do
      get plantings_path
      expect(response).to have_http_status(200)
    end
  end

  describe "POST create" do
    it 'creates a planting' do
      expect {
        post plantings_path, params: { planting: { seed_id: seed.id, planted_at: 1.day.ago } }
      }.to change { current_user.plantings.count }.by(1)
      expect(response).to redirect_to(plantings_path)
    end

    it 'handles invalid data' do
      expect {
        post plantings_path, params: { planting: { seed_id: nil, planted_at: 1.day.ago } }
      }.to_not change { current_user.plantings.count }
      expect(response).to render_template(:index)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
