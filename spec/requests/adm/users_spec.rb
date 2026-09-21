require 'rails_helper'

RSpec.describe "Adm::Users", type: :request do
  let(:user) { create(:user, :root) }
  before { sign_in user }
  describe "GET /index" do
    it 'works' do
      create_list(:user, 3)
      get adm_users_path
      expect(response).to have_http_status(200)
    end

    describe 'sorting by last_request_at' do
      let!(:never)  { create(:user, email: 'never@test.host', last_request_at: nil) }
      let!(:older)  { create(:user, email: 'older@test.host', last_request_at: 3.days.ago) }
      let!(:newer)  { create(:user, email: 'newer@test.host', last_request_at: 1.day.ago) }

      def listed_emails(sort)
        get adm_users_path(sort: sort)
        response.body.scan(/(?:never|older|newer)@test\.host/)
      end

      it 'sorts users who never made a request as the smallest value when ascending' do
        expect(listed_emails('last_request_at_asc')).to eq(%w[never@test.host older@test.host newer@test.host])
      end

      it 'sorts users who never made a request as the smallest value when descending' do
        expect(listed_emails('last_request_at_desc')).to eq(%w[newer@test.host older@test.host never@test.host])
      end
    end
  end

  describe "GET /edit" do
    let(:other_user) { create(:user) }
    it 'works' do
      get adm_users_path
      expect(response).to have_http_status(200)
    end
  end

  describe "PATCH /update" do
    let!(:other_user) { create(:user) }
    let(:params) do
      {
        user: {
          name: 'test',
          email: 'test@email.test',
          disabled: '1',
        }
      }
    end

    it 'updates the user' do
      patch adm_user_path(other_user), params: params
      expect(response).to redirect_to(adm_users_path)
      other_user.reload
      expect(other_user.name).to eq('test')
      expect(other_user.email).to eq('test@email.test')
      expect(other_user.disabled?).to eq(true)
    end

    it 'handle bad input properly' do
      patch adm_user_path(other_user), params: { user: { email: '' }}
      expect(response).to have_http_status(:unprocessable_content)
    end

  end
end
