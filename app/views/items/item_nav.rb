# frozen_string_literal: true

class Views::Items::ItemNav < Views::Items::Base

  def view_template
    primary_button_to("Food", by_use_items_path(use: "food"))
    primary_button_to("Pet Food", by_use_items_path(use: "pet-food"))
    primary_button_to("Abstract Items", abstractions_path)
    new_button_to("New Item", new_item_path) if policy(Item).edit?
    primary_button_to("Verify Items", item_verifications_path) if policy(:verification).index?
  end

end
