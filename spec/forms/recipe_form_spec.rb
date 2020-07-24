require 'rails_helper'

RSpec.describe RecipeForm do

  let(:user) { create :user, :editor }

  let(:craft_skill) { CraftSkill::WITH_RECIPES.last }

  let!(:item_1) { Item.create(name: 'Ing 1') }
  let!(:item_2) { Item.create(name: 'Ing 2') }

  let(:result_1) { Item.create(name: 'Result 1') }
  let(:result_2) { Item.create(name: 'Result 2') }

  let(:valid_attrs) do
    {
      name: 'Thing',
      craft_skill: craft_skill.key,
      results_attributes: {
        "0" => { name: result_1.name, item_id: result_1.id, count: 1 }.with_indifferent_access
      },
      ingredients_attributes: {
        "0" => { name: item_1.name, item_id: item_1.id, count: 1 }.with_indifferent_access,
        "1" => { name: item_2.name, item_id: item_2.id, count: 2 }.with_indifferent_access,
      }
    }
  end

  context 'Given a new Recipe and One Result' do
    let(:recipe) { Recipe.new }

    subject(:form) { RecipeForm.new(recipe, user) }

    it 'creates a Recipe' do
      expect { subject.save(valid_attrs)}
        .to change { Recipe.count }.by(1)

      recipe = Recipe.last
      expect(recipe.name).to eq 'Thing'
      expect(recipe.results.size).to eq 1
      expect(recipe.ingredients.size).to eq 2
    end

  end

  context 'Given an existing Recipe and Item' do
    let!(:recipe) { Recipe.new(name: 'Thing', craft_skill: craft_skill) }
    let!(:res1)   { recipe.results.build(item: result_1) }
    let!(:ing1)   { recipe.ingredients.build(item: item_1) }
    let!(:ing2)   { recipe.ingredients.build(item: item_2, count: 2) }

    before { recipe.save! }

    subject(:form) { RecipeForm.new(recipe, user) }

    it 'updates just the name of the Recipe' do
      expect { subject.save(name: 'Thing From Ingredients') }
        .to_not change { Ingredient.count }

      recipe.reload
      expect(recipe.name).to eq 'Thing From Ingredients'
    end

    it 'updates ingredients in place' do
      valid_attrs[:ingredients_attributes]['0'][:count] = 4
      expect {
        expect(subject.save(valid_attrs)).to eq true
      }.to_not change { Ingredient.count }

      recipe.reload
      ing = recipe.ingredients.find { |i| i.item == item_1 }
      expect(ing.count).to eq 4
    end

    it 'removes ingredients that are gone' do
      valid_attrs[:ingredients_attributes].delete('0')
      expect {
        expect(subject.save(valid_attrs)).to eq true
      }.to change { Ingredient.count }.by(-1)

      recipe.reload
      expect(recipe.ingredients.map(&:item)).to eq [ item_2 ]
    end

    it 'removes ingredients that have count set to zero' do
      valid_attrs[:ingredients_attributes]['1'][:count] = 0
      expect {
        expect(subject.save(valid_attrs)).to eq true
      }.to change { Ingredient.count }.by(-1)

      recipe.reload
      expect(recipe.ingredients.map(&:item)).to eq [ item_1 ]
    end

    it 'creates a revision comment' do
      valid_attrs[:name] = 'New Thing'
      valid_attrs[:ingredients_attributes]['1'][:count] = 0
      expect {subject.save(valid_attrs) }
        .to change { Comment.count }.by(1)

      comment = Comment.last
      expect(comment.subject).to eq recipe
      expect(comment.author).to eq user
      expected = { changes: {name:['Thing', 'New Thing'],},
                   ingredient_changes: {
                     removed: [[ item_2.name, 2 ]]
                   }
                 }.to_json
      expect(comment.body).to eq(expected)
    end

  end
end
