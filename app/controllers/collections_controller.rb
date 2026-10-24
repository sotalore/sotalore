# frozen_string_literal: true

# The site's own groupings of items (see Collection): browsed by anyone,
# made and arranged by editors. Items are added through
# CollectionItemsController.
class CollectionsController < ApplicationController

  def index
    authorize Collection
    collections = Collection.by_name.includes(:children).to_a
    render Views::Collections::Index.new(collections: collections, item_counts: item_counts(collections))
  end

  def show
    collection = Collection.find(params[:id])
    authorize collection
    render Views::Collections::Show.new(collection: collection, items: collection.all_items)
  end

  def new
    collection = Collection.new
    authorize collection
    parent = Collection.find_by(id: params[:parent_id])
    render Views::Collections::New.new(collection: collection, parent_ids: [ parent&.id ].compact)
  end

  def create
    collection = Collection.new(collection_params)
    authorize collection
    if save(collection)
      redirect_to collection, notice: "Created #{collection.name}."
    else
      render Views::Collections::New.new(collection: collection, parent_ids: parent_ids),
             status: :unprocessable_content
    end
  end

  def edit
    collection = Collection.find(params[:id])
    authorize collection
    render Views::Collections::Edit.new(collection: collection, parent_ids: collection.parent_ids)
  end

  def update
    collection = Collection.find(params[:id])
    authorize collection
    collection.assign_attributes(collection_params)
    if save(collection)
      redirect_to collection, notice: "Saved #{collection.name}."
    else
      render Views::Collections::Edit.new(collection: collection, parent_ids: parent_ids),
             status: :unprocessable_content
    end
  end

  def destroy
    collection = Collection.find(params[:id])
    authorize collection
    collection.destroy!
    redirect_to collections_path, notice: "Deleted #{collection.name}."
  end

  private

  def collection_params
    params.require(:collection).permit(:name, :description)
  end

  def parent_ids
    Array(params.dig(:collection, :parent_ids)).compact_blank.map(&:to_i)
  end

  # Saves the collection and the collections it's inside, all or nothing.
  # A link that would put a collection inside itself makes it invalid.
  def save(collection)
    Collection.transaction do
      collection.save!
      collection.parents = Collection.where(id: parent_ids)
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    collection.errors.add(:base, e.record.errors.full_messages.to_sentence) unless e.record == collection
    false
  end

  # { collection id => how many items it holds, counting those inside }
  def item_counts(collections)
    map = Collection.children_map
    rows = CollectionItem.pluck(:collection_id, :item_id).group_by(&:first).transform_values { _1.map(&:last) }
    collections.to_h do |collection|
      ids = [ collection.id, *collection.descendant_ids(map) ]
      [ collection.id, ids.flat_map { rows.fetch(_1, []) }.uniq.size ]
    end
  end
end
