# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Verifications", type: :request do
  let(:current_user) { create :user, :root }
  before { sign_in current_user }

  describe "GET /index" do
    context 'For items' do
      let!(:items) { create_list :item, 3 }
      it 'returns http success' do
        get item_verifications_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'For recipes' do
      let!(:recipes) { create_list :recipe, 1 }
      it 'returns http success' do
        get recipe_verifications_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH /update' do
    context 'for an item' do
      let(:item) { create :item }
      it 'verifies and returns to verifications' do
        expect(item.verified?).to be_falsey

        patch verify_item_path(item)
        expect(response).to redirect_to(item_path(item))

        item.reload
        expect(item.verified?).to be_truthy
        expect(item.verified_by).to eq(current_user)
      end
    end

    context 'for a recipe' do
      let(:recipe) { create :recipe }
      it 'verifies and returns to verifications' do
        expect(recipe.verified?).to be_falsey

        patch verify_recipe_path(recipe)
        expect(response).to redirect_to(recipe_path(recipe))

        recipe.reload
        expect(recipe.verified?).to be_truthy
        expect(recipe.verified_by).to eq(current_user)
      end
    end
  end
end
