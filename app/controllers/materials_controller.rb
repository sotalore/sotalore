# frozen_string_literal: true

# How each family of materials is gathered and refined (see
# MaterialFamily): one family a page, with the picked item's path traced.
class MaterialsController < ApplicationController

  def show
    authorize Item, :index?
    family = MaterialFamily.new(params[:family])
    item = Item.find_by(id: params[:item]) if params[:item]
    item = nil unless item && family.include?(item)
    bonuses = ComponentBonuses.new(family.materials) if item && family.materials.find(item)
    render Views::Materials::Show.new(family: family, item: item, bonuses: bonuses)
  end
end
