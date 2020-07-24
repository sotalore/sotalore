require 'rails_helper'

RSpec.describe User::UserRecipesController, type: :controller do

  let(:user) { create :user }
  before { sign_in user }

  let(:recipe) { create :recipe }

  describe 'POST create' do
    it 'adds a UserRecipe' do
      expect { post :create, xhr: true, params: { recipe_id: recipe.id } }
        .to change { UserRecipe.count }.by(1)
    end

    it 'just returns when nothing is found' do
      post :create, xhr: true, params: { recipe_id: 0 }
      expect(response).to have_http_status(:not_acceptable)
    end
  end

  context 'Given an existing recipe key' do
    let!(:existing) { user.user_recipes.create(recipe: recipe) }
    describe 'POST create' do
      it 'simply succeeds' do
        post :create, xhr: true, params: { recipe_id: recipe.id }
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'DELETE destroy' do
      it 'removes the UserRecipe' do
        delete :destroy, xhr: true, params: { id: existing, recipe_id: recipe.id }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
