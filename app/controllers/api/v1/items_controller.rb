# frozen_string_literal: true

# Items, by name or kind, and everything about one.
class Api::V1::ItemsController < Api::BaseController
  before_action -> { require_scope!('read') }

  # ?q= (name contains), ?kind=, ?use=, ?page=, ?per=
  def index
    authorize(Item)
    items = Item.by_name
    items = items.where('items.name ILIKE ?', "%#{Item.sanitize_sql_like(params[:q])}%") if params[:q].present?
    items = items.where(kind: params[:kind]) if params[:kind].presence_in(Item.kinds.keys)
    items = items.where(use: params[:use]) if params[:use].presence_in(Item.uses.keys)
    render json: paged(:items, items) { item_summary(_1) }
  end

  def show
    item = Item.includes(:aliases, :game_keys, :members, :groups, :collections).find(params[:id])
    authorize(item)
    render json: item_detail(item)
  end
end
