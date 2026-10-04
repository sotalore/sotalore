# Abstract items, a tab for each kind (see Item::ITEM_KINDS).
class AbstractionsController < ApplicationController
  before_action { authorize Item, :index? }

  def index
    redirect_to groups_abstractions_path
  end

  def groups
    render Views::Abstractions::Groups.new(items: items(:group).includes(:members), counts: counts)
  end

  def categories
    render Views::Abstractions::Categories.new(items: items(:category).includes(:members), counts: counts)
  end

  def archetypes
    items = items(:archetype).includes(recipes: { ingredients: :item })
    render Views::Abstractions::Archetypes.new(items: items, counts: counts)
  end

  private

  def items(kind)
    Item.where(kind: kind).by_name
  end

  def counts
    Item.abstract.group(:kind).count
  end

end
