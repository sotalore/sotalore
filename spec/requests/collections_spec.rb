require 'rails_helper'

RSpec.describe "Collections", type: :request do
  let(:editor) { create :user, :editor }
  let!(:armor) { Collection.create!(name: 'Armor', description: 'Things you **wear**.') }
  let!(:light) { Collection.create!(name: 'Light Armor').tap { CollectionLink.create!(parent: armor, child: _1) } }
  let(:boots)  { create :item, name: 'Fortified Leather Boots', kind: :archetype }

  it 'shows the tree and each collection to anyone' do
    light.collection_items.create!(item: boots)
    get collections_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include 'Armor', collection_path(light), '1 item'
    expect(response.body).not_to include 'New Collection'

    get collection_path(armor)
    expect(response.body).to include '<strong>wear</strong>', 'Fortified Leather Boots', collection_path(light)
  end

  context 'as an editor' do
    before { sign_in editor }

    it 'makes a collection inside others' do
      leather = Collection.create!(name: 'Leather Armor')
      get new_collection_path(parent_id: armor.id)
      expect(response).to have_http_status(:ok)

      post collections_path, params: { collection: { name: 'Fortified Leather Armor', parent_ids: [ '', light.id, leather.id ] } }
      fortified = Collection.find_by!(name: 'Fortified Leather Armor')
      expect(response).to redirect_to(fortified)
      expect(fortified.parents).to eq [ leather, light ]
    end

    it "refuses to put a collection inside itself, keeping what's there" do
      patch collection_path(armor), params: { collection: { name: 'Armour', parent_ids: [ light.id ] } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include "Armour can&#39;t be inside Light Armor: Light Armor is inside it"
      expect(armor.reload).to have_attributes(name: 'Armor', parents: [])
    end

    it 'lists items by name or id and takes them out' do
      post collection_items_path, params: { collection_item: { collection_id: light.id, item_name: boots.name } }
      expect(flash[:notice]).to eq 'Added Fortified Leather Boots to Light Armor.'
      entry = light.collection_items.sole

      get item_path(boots)
      expect(response.body).to include 'Collections:', collection_path(light), 'so also'

      delete collection_item_path(entry)
      expect(light.collection_items).to be_empty

      post collection_items_path, params: { collection_item: { collection_id: light.id, item_id: create(:item, name: 'Metal Ingot', kind: :group).id } }
      expect(flash[:alert]).to include 'must be a concrete item or an archetype'
    end

    it "can't delete a collection; root can" do
      delete collection_path(light)
      expect(Collection.exists?(light.id)).to be true
      sign_in create(:user, :root)
      delete collection_path(light)
      expect(Collection.exists?(light.id)).to be false
      expect(CollectionLink.count).to eq 0
    end
  end

  it "doesn't let regular users change collections" do
    sign_in create(:user)
    post collections_path, params: { collection: { name: 'Mine' } }
    post collection_items_path, params: { collection_item: { collection_id: light.id, item_id: boots.id } }
    expect(Collection.find_by(name: 'Mine')).to be_nil
    expect(light.collection_items).to be_empty
  end
end
