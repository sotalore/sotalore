require 'rails_helper'

RSpec.describe "Abstractions", type: :request do
  describe "GET /abstractions" do
    it "lists abstract items by kind" do
      create :item, name: 'Metal Ingot', kind: :group
      create :item, name: 'Dagger', kind: :archetype
      create :item, name: 'Crafted Carpentry Equipable', kind: :category
      get abstractions_path
      expect(response).to have_http_status(200)
      expect(response.body).to include('Groups', 'Archetypes', 'Categories', 'Metal Ingot', 'Dagger',
                                       'Crafted Carpentry Equipable')
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
