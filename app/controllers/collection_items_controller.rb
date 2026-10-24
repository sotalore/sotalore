# frozen_string_literal: true

# Lists items in collections and takes them out again, from a collection's
# page (the item given by id from autocomplete, or by name) or an item's
# page (the collection chosen from a list).
class CollectionItemsController < ApplicationController

  def create
    collection = Collection.find_by(id: collection_item_params[:collection_id])
    authorize collection || Collection, :update?
    entry = CollectionItem.new(collection: collection, item: find_item)
    if entry.save
      flash.notice = "Added #{entry.item} to #{entry.collection}."
    else
      flash.alert = entry.errors.full_messages.to_sentence
    end
    redirect_back_or_to(collection || collections_path)
  end

  def destroy
    entry = CollectionItem.find(params[:id])
    authorize entry.collection, :update?
    entry.destroy!
    redirect_back_or_to entry.collection, notice: "Removed #{entry.item} from #{entry.collection}."
  end

  private

  def collection_item_params
    params.require(:collection_item).permit(:collection_id, :item_id, :item_name)
  end

  def find_item
    attrs = collection_item_params
    if attrs[:item_id].present?
      Item.find_by(id: attrs[:item_id])
    elsif attrs[:item_name].present?
      Item.find_by_name(attrs[:item_name].strip).first
    end
  end
end
