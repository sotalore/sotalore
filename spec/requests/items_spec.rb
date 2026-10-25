require 'rails_helper'

RSpec.describe "Items", type: :request do

  context 'Given current_user is root' do
    let(:current_user) { create :user, :root }
    before { sign_in current_user }

    it_behaves_like "an editable resource" do
      let(:model) { Item }
      let(:fixture) { :item }
      let(:invalid_attributes) { { name: '' } }
    end
  end

  context 'Given current_user is a regular user' do
    let(:current_user) { create :user }
    before { sign_in current_user }

    it_behaves_like "a non-editable resource" do
      let(:model) { Item }
      let(:fixture) { :item }
    end
  end

  describe 'GET by_use' do
    it 'works' do
      get by_use_items_path(use: 'food')
      expect(response).to have_http_status(:ok)
    end
  end

end

RSpec.describe "Gear", type: :request do
  def gear(name, line)
    create(:item, name: name).tap do |item|
      item.game_keys.create!(key: item_key(name), name: name, catalog: { 'details' => { 'types' => [ line ] } })
    end
  end

  let!(:helm)  { gear('Rusty Chainmail Helm', 'Chain Heavy Armor (Head)') }
  let!(:hat)   { gear('Steampunk Top Hat', 'Leather Light Armor (Head)') }
  let!(:sword) { gear('Rusty Sword +1', 'Longsword - Bladed') }

  it 'lists gear by what the game calls it, filtered by facet' do
    get gear_items_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include 'Rusty Chainmail Helm', 'Steampunk Top Hat', 'Rusty Sword +1', '3 items'

    get gear_items_path(kind: 'armor', slot: 'head', weight: 'heavy')
    expect(response.body).to include 'Rusty Chainmail Helm', 'Chain Heavy Armor (Head)'
    expect(response.body).not_to include 'Steampunk Top Hat', 'Rusty Sword +1'

    get gear_items_path(damage: 'bladed', weight: 'nonsense')
    expect(response.body).to include 'Rusty Sword +1'
    expect(response.body).not_to include 'Rusty Chainmail Helm'
  end

  it "tags an item with its type line, linking to gear like it" do
    get item_path(hat)
    expect(response.body).to include 'Leather Light Armor (Head)', gear_items_path(kind: 'armor', weight: 'light', slot: 'head')
  end
end

RSpec.describe "Item effects from the game", type: :request do
  it "shows the tooltip's effects beside what someone wrote, and a component's crafting bonus" do
    dagger = create(:item, name: 'Rusty Dagger', effects: 'Found on bandits.')
    dagger.game_keys.create!(key: item_key('dagger'), name: dagger.name,
                             catalog: { 'details' => { 'effects' => [ '+40% Poison Effectiveness Bonus' ] } })
    hilt = create(:item, name: 'Elven Hilt')
    hilt.game_keys.create!(key: item_key('hilt'), name: hilt.name,
                           catalog: { 'details' => { 'craftingBonus' => [ '+3 Dexterity' ] } })

    get item_path(dagger)
    expect(response.body).to include 'Found on bandits.', "The game&#39;s tooltip:", '+40% Poison Effectiveness Bonus'
    expect(response.body).not_to include 'Crafting Bonus'

    get item_path(hilt)
    expect(response.body).to include 'Crafting Bonus', 'Gear crafted with Elven Hilt gets:', '+3 Dexterity'
  end
end
