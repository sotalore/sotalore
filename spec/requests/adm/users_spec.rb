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
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:edit)
    end

  end
end
