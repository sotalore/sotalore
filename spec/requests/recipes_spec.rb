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
        expect(response).to have_http_status(:unprocessable_content)
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

      it 'hides retired recipes unless asked' do
        recipe.update_columns(name: 'Retired Thing', retired_at: 1.day.ago)
        get recipes_path
        expect(response.body).not_to include 'Retired Thing'
        get recipes_path(retired: 1)
        expect(response.body).to include 'Retired Thing'
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

      it 'relates template and concrete recipes' do
        blade = create :item, name: 'Dagger Blade', kind: :group
        iron  = create :item, name: 'Iron Dagger Blade'
        ItemMembership.create!(group: blade, member: iron)
        template = create :recipe, name: 'Dagger Blade', with_results: { blade => 1 },
                                   with_ingredients: { create(:item) => 1 }
        concrete = create :recipe, name: 'Iron Dagger Blade', with_results: { iron => 1 },
                                   with_ingredients: { create(:item) => 2 }

        get recipe_path(template)
        expect(response.body).to include 'This is a template recipe'
        expect(response.body).to include recipe_path(concrete)

        get recipe_path(concrete)
        expect(response.body).to include 'See the general recipe'
        expect(response.body).to include recipe_path(template)
      end

      it 'explains an archetype recipe' do
        blade  = create :item, name: 'Dagger Blade', kind: :group
        dagger = create :item, name: 'Dagger', kind: :archetype
        recipe = create :recipe, name: 'Dagger', with_results: { dagger => 1 },
                                 with_ingredients: { blade => 1 }
        get recipe_path(recipe)
        expect(response.body).to include 'Which one you get depends on which'
        expect(response.body).to include item_path(blade)
        expect(response.body).not_to include 'This is a template recipe'
      end

      it 'explains a modification recipe, and lists it on the item' do
        equipable = create :item, name: 'Crafted Carpentry Equipable', kind: :category
        recipe = create :recipe, name: 'Masterwork Carpentry Upgrade', with_results: { equipable => 1 },
                                 with_ingredients: { equipable => 1, create(:item) => 1 }
        get recipe_path(recipe)
        expect(response.body).to include 'This modifies'
        expect(response.body).to include 'what you put in is what you get back'

        get item_path(equipable)
        expect(response.body).to include 'Modified by 1 Recipe'
        expect(response.body).not_to include 'no recipes make this'
      end

      it 'flags a retired recipe' do
        recipe.retire!
        get recipe_path(recipe)
        expect(response.body).to include 'This recipe is retired'
        expect(response.body).to include unretire_adm_recipe_path(recipe)
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
        expect(response).to have_http_status(:unprocessable_content)
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
