require 'rails_helper'

RSpec.describe TemplateExpansion do
  let(:editor) { create(:user, :editor) }
  let(:mingot) { create :item, name: 'Metal Ingot', kind: :group }
  let(:iron)   { create :item, name: 'Iron Ingot' }
  let(:bronze) { create :item, name: 'Bronze Ingot' }
  let(:mold)   { create :item, name: 'Sword Blade Mold' }
  let(:blade)  { create :item, name: 'Metal Sword Blade', kind: :group, use: 'weapon' }

  let!(:template) do
    create :recipe, name: 'Sword Blade', craft_skill: 'blacksmithing', proficiency: 10,
           with_ingredients: { mingot => 5, mold => 1 }, with_results: { blade => 1 }
  end

  before do
    ItemMembership.create!(group: mingot, member: iron)
    ItemMembership.create!(group: mingot, member: bronze)
  end

  subject(:expansion) { described_class.new(template) }

  it 'previews a variant per group member' do
    expect(expansion).to be_valid
    expect(expansion.variants.map(&:recipe_name)).to contain_exactly('Iron Sword Blade', 'Bronze Sword Blade')
    expect(expansion.variants).to all(satisfy { !_1.complete? })
  end

  it 'creates items, memberships, and recipes' do
    expect { expansion.apply!(editor) }
      .to change(Recipe, :count).by(2).and change(ItemMembership, :count).by(2)

    item = Item.find_by_name('Iron Sword Blade').first
    expect(item).to be_concrete
    expect(item.use).to eq 'weapon'
    expect(blade.members).to include(item)

    recipe = Recipe.find_by_name('Iron Sword Blade')
    expect(recipe.craft_skill).to eq template.craft_skill
    expect(recipe.proficiency).to eq 10
    expect(recipe.ingredients.map { [ _1.item, _1.count ] }).to contain_exactly([ iron, 5 ], [ mold, 1 ])
    expect(recipe.results.map { [ _1.item, _1.count ] }).to eq [ [ item, 1 ] ]
  end

  it 'is idempotent and leaves existing things alone' do
    expansion.apply!(editor)
    expect { described_class.new(template).apply!(editor) }
      .not_to change { [ Item.count, Recipe.count, ItemMembership.count ] }
    expect(described_class.new(template).variants).to all(be_complete)
  end

  it 'only creates the chosen members' do
    expansion.apply!(editor, members: [ iron ])
    expect(Recipe.find_by_name('Iron Sword Blade')).to be_present
    expect(Recipe.find_by_name('Bronze Sword Blade')).to be_nil
  end

  it 'completes a partly made variant' do
    existing = create :item, name: 'Iron Sword Blade'
    expect { expansion.apply!(editor, members: [ iron ]) }.not_to change(Item, :count)
    expect(blade.members).to include(existing)
  end

  it 'puts the member first when the group does not name the material' do
    dagger = create :item, name: 'Dagger Blade', kind: :group
    recipe = create :recipe, name: 'Dagger Blade', with_ingredients: { mingot => 1 }, with_results: { dagger => 1 }
    expansion = described_class.new(recipe)
    expect(expansion).to be_valid
    expect(expansion.variants.map(&:recipe_name)).to contain_exactly('Iron Dagger Blade', 'Bronze Dagger Blade')
    expansion.apply!(editor)
    expect(dagger.members.map(&:name)).to contain_exactly('Iron Dagger Blade', 'Bronze Dagger Blade')
  end

  it 'is invalid when the ingredient group has no members to learn the pattern from' do
    empty = create :item, name: 'Empty Group', kind: :group
    other = create :item, name: 'Blade Thing', kind: :group
    recipe = create :recipe, with_ingredients: { empty => 1 }, with_results: { other => 1 }
    expect(described_class.new(recipe)).not_to be_valid
  end
end

RSpec.describe 'Recipe variants', type: :request do
  let(:mingot) { create :item, name: 'Metal Ingot', kind: :group }
  let(:iron)   { create :item, name: 'Iron Ingot' }
  let(:blade)  { create :item, name: 'Metal Sword Blade', kind: :group }
  let!(:template) { create :recipe, name: 'Sword Blade', with_ingredients: { mingot => 5 }, with_results: { blade => 1 } }

  before { ItemMembership.create!(group: mingot, member: iron) }

  it 'previews and generates for editors' do
    sign_in create(:user, :editor)
    get variants_recipe_path(template)
    expect(response.body).to include 'Iron Sword Blade'

    expect { post variants_recipe_path(template), params: { member_ids: [ iron.id ] } }
      .to change(Recipe, :count).by(1)
    expect(response).to redirect_to(recipe_path(template))
  end

  it 'is not allowed for regular users' do
    sign_in create(:user)
    expect { post variants_recipe_path(template), params: { member_ids: [ iron.id ] } }
      .not_to change(Recipe, :count)
  end
end

RSpec.describe 'Group item page', type: :request do
  let(:mingot) { create :item, name: 'Metal Ingot', kind: :group }
  let(:blade)  { create :item, name: 'Metal Sword Blade', kind: :group }
  let!(:template) { create :recipe, name: 'Sword Blade', with_ingredients: { mingot => 5 }, with_results: { blade => 1 } }

  it 'links editors to the template variants page' do
    sign_in create(:user, :editor)
    get item_path(blade)
    expect(response.body).to include variants_recipe_path(template)
  end

  it 'does not show the link to regular users' do
    sign_in create(:user)
    get item_path(blade)
    expect(response.body).not_to include variants_recipe_path(template)
  end
end

RSpec.describe TemplateExpansion, 'basic materials' do
  let(:editor) { create(:user, :editor) }
  let(:mingot) { create :item, name: 'Metal Ingot', kind: :group }
  let(:iron)   { create :item, name: 'Iron Ingot', basic: true }
  let(:white)  { create :item, name: 'White Iron Ingot' }
  let(:blade)  { create :item, name: 'Metal Hilt', kind: :group }
  let!(:template) do
    create :recipe, name: 'Hilt', craft_skill: 'blacksmithing', proficiency: 30,
           with_ingredients: { mingot => 2 }, with_results: { blade => 1 }
  end

  before do
    ItemMembership.create!(group: mingot, member: iron)
    ItemMembership.create!(group: mingot, member: white)
  end

  it 'defaults by material and carries basic onto new items' do
    expansion = described_class.new(template)
    expansion.apply!(editor)

    easy = Recipe.find_by_name('Iron Hilt')
    expect([ easy.proficiency, easy.teachable ]).to eq [ 1, 're_teachable' ]
    expect(Item.find_by_name('Iron Hilt').first).to be_basic

    hard = Recipe.find_by_name('White Iron Hilt')
    expect([ hard.proficiency, hard.teachable ]).to eq [ 30, 'not_teachable' ]
    expect(Item.find_by_name('White Iron Hilt').first).not_to be_basic
  end

  it 'uses entered settings' do
    described_class.new(template).apply!(editor, members: [ white ],
      settings: { white.id => { proficiency: 45, teachable: 'teachable' } })
    recipe = Recipe.find_by_name('White Iron Hilt')
    expect([ recipe.proficiency, recipe.teachable ]).to eq [ 45, 'teachable' ]
  end

end

RSpec.describe 'Recipe variant settings', type: :request do
  let(:mingot) { create :item, name: 'Metal Ingot', kind: :group }
  let(:white)  { create :item, name: 'White Iron Ingot' }
  let(:hilt)   { create :item, name: 'Metal Hilt', kind: :group }
  let!(:template) { create :recipe, name: 'Hilt', with_ingredients: { mingot => 2 }, with_results: { hilt => 1 } }

  before { ItemMembership.create!(group: mingot, member: white) }

  it 'takes settings from the variants page' do
    sign_in create(:user, :editor)
    post variants_recipe_path(template), params: {
      member_ids: [ white.id ], variants: { white.id => { proficiency: '40', teachable: 're_teachable' } }
    }
    recipe = Recipe.find_by_name('White Iron Hilt')
    expect([ recipe.proficiency, recipe.teachable ]).to eq [ 40, 're_teachable' ]
  end
end
