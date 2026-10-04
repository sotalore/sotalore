require 'rails_helper'

RSpec.describe "Abstractions", type: :request do
  describe "GET /abstractions" do
    it "lists abstract items by kind" do
      create :item, name: 'Metal Ingot', kind: :group
      create :item, name: 'Dagger', kind: :archetype
      create :item, name: 'Crafted Carpentry Equipable', kind: :category
      armor = create :item, name: 'Crafted Chest Armor', kind: :category
      ItemMembership.create!(group: armor, member: create(:item, name: 'Plate Chest'))
      get abstractions_path
      expect(response).to have_http_status(200)
      expect(response.body).to include('Groups', 'Archetypes', 'Categories', 'Metal Ingot', 'Dagger',
                                       'Crafted Carpentry Equipable', 'Categories with Examples',
                                       'Crafted Chest Armor', 'Plate Chest')
    end

    it "shows a category's examples, and what a concrete item is an example of" do
      armor = create :item, name: 'Crafted Chest Armor', kind: :category
      ingot = create :item, name: 'Metal Ingot', kind: :group
      plate = create :item, name: 'Plate Chest'
      ItemMembership.create!(group: armor, member: plate)
      ItemMembership.create!(group: ingot, member: plate)

      get item_path(armor)
      expect(response.body).to include('Some examples of Crafted Chest Armor', 'Plate Chest')

      get item_path(plate)
      expect(response.body).to include('Member of', 'Metal Ingot', 'Example of', 'Crafted Chest Armor')
    end

    it "shows each kind on its item page" do
      %i[ group archetype category ].each do |kind|
        item = create :item, kind: kind
        get item_path(item)
        expect(response).to have_http_status(200)
        expect(response.body).to include(kind == :group ? 'Group Members' : kind.to_s.capitalize)
      end
    end
  end
end
