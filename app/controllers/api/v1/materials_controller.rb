# frozen_string_literal: true

# The crafting materials (see Materials), by family and tier.
class Api::V1::MaterialsController < Api::BaseController
  before_action -> { require_scope!('read') }

  # Every material: there are few, so no paging.
  def index
    authorize(Item, :index?)
    materials = Materials.new
    render json: { materials: materials.all.map { material_json(_1, materials) } }
  end
end
