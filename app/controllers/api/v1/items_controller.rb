# frozen_string_literal: true

# Items, by name or kind, and everything about one.
class Api::V1::ItemsController < Api::BaseController
  before_action -> { require_scope!('read') }

  # ?q= (name contains), ?kind=, ?page=, ?per=
  def index
    authorize(Item)
    items = Item.by_name
    items = items.where('items.name ILIKE ?', "%#{Item.sanitize_sql_like(params[:q])}%") if params[:q].present?
    items = items.where(kind: params[:kind]) if params[:kind].presence_in(Item.kinds.keys)
    render json: paged(:items, items) { item_summary(_1) }
  end

  def show
    item = Item.includes(:aliases, :game_keys, :members, :groups).find(params[:id])
    authorize(item)
    render json: item_detail(item)
  end
end
