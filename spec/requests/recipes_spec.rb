require 'rails_helper'

RSpec.describe "Recipes", type: :request do
  let(:user) { create :user, :root }
  before     { sign_in user }

  context 'Given no existing recipe' do
    describe 'GET new' do
      it 'works' do
        get new_recipe_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'POST create' do
      let(:item) { create :item }

      it 'creates the recipe with valid changes' do
        post recipes_path, params: {
               recipe: { name: 'A New Name',
                         craft_skill: 'carpentry',
                         results_attributes: {
                           "0" => {
                             item_id: item.id, count: 1
                           }
                         },
                         ingredients_attributes: {
                           "0" => {
                             item_id: item.id, count: 1
                           }
                         }
                       }
              }
        expect(response).to redirect_to(Recipe.last)
      end

      it 'renders the form with invalid changes' do
        post recipes_path, params: {
                recipe: { name: '' }
              }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context 'Given an existing recipe' do
    let!(:recipe) { create :recipe }

    describe 'GET index' do
      it 'works' do
        get recipes_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET for_item' do
      it 'works' do
        get item_recipes_path(item_id: recipe.results.first.item)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET show' do
      it 'works' do
        get recipe_path(recipe)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET edit' do
      it 'works' do
        get edit_recipe_path(recipe)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PATCH update' do
      it 'updates the recipe with valid changes' do
        patch recipe_path(recipe), params: { recipe: { name: 'A New Name' } }
        expect(response).to redirect_to(recipe)
      end

      it 'renders the form with invalid changes' do
        patch recipe_path(recipe), params: { recipe: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'DELETE destroy' do
      it 'deletes the recipe' do
        expect { delete recipe_path(recipe) }
          .to change { Recipe.count }.by(-1)
        expect(response).to redirect_to(action: :index)
      end
    end

  end
end
