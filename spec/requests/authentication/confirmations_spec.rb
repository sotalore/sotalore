# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Authentication::Confirmations", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get new_user_confirmation_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    context 'Given a valid email' do
      let(:user) { create(:user) }
      it 'sends a confirmation email' do
        clear_enqueued_jobs

        expect {
           post user_confirmation_path, params: { user: { email: user.email } }
           perform_enqueued_jobs
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context 'Given an invalid email' do
      it 'does not send a confirmation email' do
        expect { post user_confirmation_path, params: { user: { email: 'invalid@foo.bar' } } }
          .to_not change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end
