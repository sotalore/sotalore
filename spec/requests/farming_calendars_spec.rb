require 'rails_helper'

RSpec.describe "FarmingCalendars", type: :request do
  describe "GET /index" do
    it 'works' do
      get farming_calendar_path(start: Time.zone.now, seedTime: 8, locationFactor: 1.0, name: 'Farm Watering')
      expect(response).to have_http_status(200)
    end
  end
end
