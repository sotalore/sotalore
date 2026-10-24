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

      it "lists an archetype recipe's options, with their effects, and links to them from the item" do
        blade  = create :item, name: 'Dagger Blade', kind: :group
        hilt   = create :item, name: 'Metal Hilt', kind: :group
        dagger = create :item, name: 'Dagger', kind: :archetype
        { blade => [ 'Iron Dagger Blade', 'Bronze Dagger Blade' ], hilt => [ 'Copper Hilt' ] }.each do |group, names|
          names.each { ItemMembership.create!(group: group, member: create(:item, name: _1)) }
        end
        Item.find_by!(name: 'Copper Hilt').update!(effects: '+1% Weapon Critical Chance')
        recipe = create :recipe, name: 'Dagger', with_results: { dagger => 1 },
                                 with_ingredients: { blade => 1, hilt => 1 }

        get recipe_path(recipe)
        expect(response.body).to include '2 Dagger Blade × 1 Metal Hilt, 2 combinations'
        expect(response.body).to include 'Bronze Dagger Blade', '+1% Weapon Critical Chance'

        get item_path(dagger)
        expect(response.body).to include 'See every option', recipe_path(recipe)
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

      it "loads an ingredient's own recipe in a lazy frame, shown on request" do
        part = create :item, name: 'Blade'
        part_recipe = create :recipe, name: 'Blade', with_results: { part => 1 }, with_ingredients: { create(:item) => 1 }
        whole = create :recipe, name: 'Sword', with_ingredients: { part => 1 }
        frame_id = ActionView::RecordIdentifier.dom_id(part_recipe, ActionView::RecordIdentifier.dom_id(whole.ingredients.first))

        get recipe_path(whole)
        expect(response.body).to include(%(data-more-link-frame-param="#{frame_id}"))
        frame = Nokogiri::HTML(response.body).at_css("turbo-frame##{frame_id}")
        expect(frame.to_h).to include('src' => show_partial_recipe_path(part_recipe), 'loading' => 'lazy',
                                      'target' => '_top', 'hidden' => 'hidden')

        get show_partial_recipe_path(part_recipe), headers: { 'Turbo-Frame' => frame_id }
        expect(response.body).to start_with(%(<turbo-frame id="#{frame_id}">))
        expect(response.body).to include(part_recipe.name)
      end

      it 'deletes with a form button, confirming first' do
        get recipe_path(recipe)
        form = Nokogiri::HTML(response.body).at_css(%(form[action="#{recipe_path(recipe)}"][method="post"]))
        expect(form['data-turbo-confirm']).to eq 'Are you sure?'
        expect(form.at_css('input[name="_method"]')['value']).to eq 'delete'
        expect(form.at_css('button').text).to include 'Delete Recipe'
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
