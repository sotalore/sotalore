# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Cabalists", type: :request do
  describe "GET /show" do
    it 'works' do
      get cabalists_path
      expect(response).to have_http_status(200)
    end
  end
end
