require "rails_helper"

RSpec.describe HomeController do

  describe 'GET show' do
    it 'works' do
      get :show
      expect(response).to have_http_status(:ok)
    end

    it 'sets a key for anonymous users' do
      expect {
        get :show
      }.to change { cookies[:user_key] }.from(nil)

      expect(controller.send(:current_user).user_key)
        .to eq cookies[:user_key]
    end

    context 'Given the user has a cookied key' do
      before do
        cookies[:user_key] = 'existing'
      end
      it 'does not change it' do
        expect {
          get :show
        }.to_not change { cookies[:user_key] }.from('existing')
      end

      it 'provides the key in the NullUser' do
        get :show
        expect(controller.send(:current_user).user_key).to eq 'existing'
      end
    end
  end

  describe 'GET master_trainers' do
    render_views
    it 'works' do
      get :master_trainers
      expect(response).to have_http_status(:ok)
    end

  end
end
