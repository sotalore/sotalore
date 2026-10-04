require 'rails_helper'

RSpec.describe "Abstractions", type: :request do
  describe "GET /abstractions" do
    it "starts on the groups tab" do
      get abstractions_path
      expect(response).to redirect_to(groups_abstractions_path)
    end

    it "lists groups with all their members" do
      ingot = create :item, name: 'Metal Ingot', kind: :group
      %w[ Bronze Copper Iron ].each { ItemMembership.create!(group: ingot, member: create(:item, name: "#{_1} Ingot")) }
      create :item, name: 'Dagger', kind: :archetype
      get groups_abstractions_path
      expect(response).to have_http_status(200)
      expect(response.body).to include('Groups (1)', 'Archetypes (1)', 'Categories (0)', 'Metal Ingot',
                                       'Bronze Ingot', 'Copper Ingot', 'Iron Ingot')
      expect(response.body).not_to include('Dagger')
    end

    it "lists categories with some examples" do
      armor = create :item, name: 'Crafted Chest Armor', kind: :category
      create :item, name: 'Back Slot Equipment', kind: :category
      9.times { ItemMembership.create!(group: armor, member: create(:item, name: "Chest #{_1}")) }
      get categories_abstractions_path
      expect(response).to have_http_status(200)
      expect(response.body).to include('Crafted Chest Armor', 'Chest 7', 'and 1 more', 'Back Slot Equipment',
                                       'none yet')
      expect(response.body).not_to include('Chest 8')
    end

    it "lists archetypes by the craft skill making them, with the groups to choose from" do
      dagger = create :item, name: 'Dagger', kind: :archetype
      create :item, name: 'Bucket Hat', kind: :archetype
      blade  = create :item, name: 'Dagger Blade', kind: :group
      create(:recipe, name: 'Dagger', craft_skill: 'blacksmithing',
                      with_ingredients: { blade => 1, create(:item, name: 'Hilt Wrap') => 1 },
                      with_results: { dagger => 1 })
      get archetypes_abstractions_path
      expect(response).to have_http_status(200)
      expect(response.body).to include('Blacksmithing', 'Dagger Blade', 'Not made by any recipe yet', 'Bucket Hat')
      expect(response.body).not_to include('Hilt Wrap')
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
