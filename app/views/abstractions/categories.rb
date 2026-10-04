# frozen_string_literal: true

class Views::Abstractions::Categories < Views::Abstractions::Base

  EXAMPLES_SHOWN = 8

  private

  def kind = 'category'

  def intro
    p do
      plain "A "
      strong { "category" }
      plain " describes a broad kind of item, like \"Crafted Chest Armor\" or \"Back Slot "
      plain "Equipment\". Anything that fits belongs to it, so there are too many to list."
    end
    p do
      plain "Categories are often what an upgrade or modification recipe can be used on. "
      plain "The items shown are just examples."
    end
  end

  def content
    members_table("Examples", limit: EXAMPLES_SHOWN)
  end

end
