# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Times", type: :request do
  describe "GET /index" do
    it 'works' do
      get time_path
      expect(response).to have_http_status(200)
    end
  end
end
