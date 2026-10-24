require 'rails_helper'

RSpec.describe "Adm::ArchetypeCleanups", type: :request do
  let(:user) { create(:user, :root) }
  before { sign_in user }

  let(:blade) { create(:item, name: 'Dagger Blade', kind: :group) }
  let(:iron_blade) { create(:item, name: 'Iron Dagger Blade').tap { ItemMembership.create!(group: blade, member: _1) } }
  let!(:dagger) do
    create(:recipe, name: 'Dagger', craft_skill: 'blacksmithing', game_id: 1, with_ingredients: { blade => 1 },
                    with_results: { create(:item, name: 'Dagger', kind: :archetype) => 1 })
  end
  let!(:old) do
    create(:recipe, name: 'Iron Dagger with Iron Hilt', craft_skill: 'blacksmithing',
                    with_ingredients: { iron_blade => 1 },
                    with_results: { create(:item, name: 'Iron Dagger with Iron Hilt') => 1 })
  end

  it 'lists the old recipes each archetype recipe covers' do
    get adm_archetype_cleanup_path
    expect(response).to have_http_status(200)
    expect(response.body).to include 'Iron Dagger with Iron Hilt', recipe_path(dagger), 'fits', '(deleted)'
  end

  it "says what doesn't fit" do
    create(:recipe, name: 'Crimson Dagger of Haste', craft_skill: 'blacksmithing',
                    with_ingredients: { create(:item, name: 'Crimson Blade') => 1 },
                    with_results: { create(:item, name: 'Crimson Dagger of Haste') => 1 })
    get adm_archetype_cleanup_path
    expect(response.body).to include 'Crimson Blade isn&#39;t in the game&#39;s recipe', 'no Dagger Blade'
  end

  it 'deletes the ticked recipes and their items' do
    expect { delete adm_archetype_cleanup_path, params: { recipe_ids: [ old.id ] } }
      .to change(Recipe, :count).by(-1).and change(Item, :count).by(-1)
    expect(flash[:notice]).to eq 'Deleted 1 recipe and 1 item.'
  end

  it "is root's alone" do
    sign_in create(:user)
    delete adm_archetype_cleanup_path, params: { recipe_ids: [ old.id ] }
    expect(Recipe.exists?(old.id)).to be true
  end
end
