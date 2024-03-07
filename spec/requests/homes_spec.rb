require 'rails_helper'

RSpec.describe "HomeController", type: :request do
  describe "GET /" do
    before do
      # for the random recipes on root
      create(:recipe)
    end

    it "works" do
      get root_path
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET show' do
    it 'sets a key for anonymous users' do
      expect { get root_path }
        .to change { cookies[:user_key] }.from(nil)
    end

    context 'Given the user has a cookied key' do
      before do
        cookies[:user_key] = 'existing'
      end
      it 'does not change it' do
        expect { get root_path }
          .to_not change { cookies[:user_key] }.from('existing')
      end
    end
  end

  describe 'GET master_trainers' do
    it 'works' do
      get master_trainers_path
      expect(response).to have_http_status(:ok)
    end

  end

end
