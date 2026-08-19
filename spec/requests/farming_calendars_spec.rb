require 'rails_helper'

RSpec.describe "FarmingCalendars", type: :request do
  describe "GET /index" do
    it 'works' do
      start_time = Time.zone.now
      get farming_calendar_path(start: start_time, seedTime: 8, locationFactor: 10, name: 'Farm Watering')
      expect(response).to have_http_status(200)

      body = response.body
      body.split
      starts = body.split.select { |l| l.starts_with?('DTSTART') }
      expect(starts.size).to eq(5)

      start_time = start_time.utc
      expect(starts[0]).to eq("DTSTART:19700101T000000")
      expect(starts[1]).to eq("DTSTART:#{start_time.strftime('%Y%m%dT%H%M%S')}")
      expect(starts[2]).to eq("DTSTART:#{(start_time + 80.hours).strftime('%Y%m%dT%H%M%S')}")
      expect(starts[3]).to eq("DTSTART:#{(start_time + 160.hours).strftime('%Y%m%dT%H%M%S')}")
      expect(starts[4]).to eq("DTSTART:#{(start_time + 240.hours).strftime('%Y%m%dT%H%M%S')}")
    end

    it 'redirects instead of erroring when no params are given (e.g. bots hitting the bare URL)' do
      get farming_calendar_path
      expect(response).to redirect_to(farming_path)
    end

    it 'redirects when the start param is unparseable' do
      get farming_calendar_path(start: 'not-a-time', seedTime: 8, locationFactor: 10, name: 'Farm Watering')
      expect(response).to redirect_to(farming_path)
    end

    it 'redirects when seedTime is not a number' do
      start_time = Time.zone.now
      get farming_calendar_path(start: start_time, seedTime: 'abc', locationFactor: 10, name: 'Farm Watering')
      expect(response).to redirect_to(farming_path)
    end

    it 'redirects when locationFactor is not a number' do
      start_time = Time.zone.now
      get farming_calendar_path(start: start_time, seedTime: 8, locationFactor: 'abc', name: 'Farm Watering')
      expect(response).to redirect_to(farming_path)
    end
  end
end
