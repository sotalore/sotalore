# frozen_string_literal: true

# Upload, review and apply item catalogs from the game plugin (see
# ItemCatalogImport).
class Adm::ItemCatalogImportsController < AdmController
  include ResolvesGameItems

  def index
    authorize(ItemCatalogImport)
    page_title 'Item Catalog Imports'
    render Views::Adm::ItemCatalogImports::Index.new(
      imports: ItemCatalogImport.newest_first.includes(:uploaded_by).page(params[:page])
    )
  end

  def create
    authorize(ItemCatalogImport)
    file = params[:file].presence
    unless file
      redirect_to adm_item_catalog_imports_path, alert: 'Choose an item catalog (sotalore-items.json).'
      return
    end
    import = ItemCatalogImport.create_from_json!(file.read, filename: file.original_filename, user: Current.user)
    redirect_to adm_item_catalog_import_path(import), notice: "Imported #{import.catalog.entries.size} items."
  rescue JSON::ParserError, ArgumentError => e
    redirect_to adm_item_catalog_imports_path, alert: "Couldn't import that: #{e.message.truncate(200)}"
  end

  def show
    @import = find_import
    authorize(@import)
    page_title @import.to_s
    render Views::Adm::ItemCatalogImports::Show.new(import: @import, analysis: @import.analysis,
                                                    open: params[:open].presence)
  end

  def destroy
    @import = find_import
    authorize(@import)
    @import.destroy
    redirect_to adm_item_catalog_imports_path, notice: "Deleted #{@import}."
  end

  def apply
    @import = find_import
    authorize(@import)
    counts = @import.apply!(Current.user)
    summary = [
      "#{counts[:keys]} game #{'key'.pluralize(counts[:keys])} recorded",
      "#{counts[:weights]} #{'weight'.pluralize(counts[:weights])} filled",
      "#{counts[:tools]} #{'tool'.pluralize(counts[:tools])} set",
      "#{counts[:salvage_added]} salvage #{'result'.pluralize(counts[:salvage_added])} added",
      "#{counts[:salvage_updated]} updated",
    ]
    redirect_to adm_item_catalog_import_path(@import), notice: "Applied: #{summary.to_sentence}."
  rescue ItemCatalogImport::Error => e
    redirect_to adm_item_catalog_import_path(@import), alert: e.message
  end

  # Creates or uses an item for an unknown one (+resolution+ create or use),
  # or creates many (+resolution+ create_many, +selected+ as JSON
  # { name:, key: } each).
  def resolve
    @import = find_import
    authorize(@import)
    notice =
      case params[:resolution]
      when 'create_many'
        create_selected_items(@import)
      when 'create'
        item = @import.create_item!(name: params.require(:name), key: params[:key].presence)
        "Created #{item.name}."
      when 'use'
        item = find_item or raise ItemCatalogImport::Error, 'Choose an existing item.'
        @import.use_item!(item, name: params.require(:name), key: params[:key].presence)
        "#{item.name} is now #{params[:name]} in the game."
      else
        raise ActionController::BadRequest, 'unknown resolution'
      end
    redirect_to review_path, notice: notice
  rescue ItemCatalogImport::Error, ActiveRecord::RecordInvalid => e
    redirect_to review_path, alert: e.message
  end

  def update_weights
    @import = find_import
    authorize(@import)
    updated = @import.update_weights!(Current.user)
    redirect_to adm_item_catalog_import_path(@import),
                notice: "Updated #{updated} #{'weight'.pluralize(updated)} to the game's."
  rescue ItemCatalogImport::Error => e
    redirect_to adm_item_catalog_import_path(@import), alert: e.message
  end

  def remove_salvage
    @import = find_import
    authorize(@import)
    item = Item.find(params.require(:item_id))
    removed = @import.remove_extra_salvage!(item)
    redirect_to adm_item_catalog_import_path(@import),
                notice: "Removed #{removed} #{'salvage'.pluralize(removed)} from #{item.name}."
  rescue ItemCatalogImport::Error => e
    redirect_to adm_item_catalog_import_path(@import), alert: e.message
  end

  private

  # Back to the review, with the section acted on still open.
  def review_path
    adm_item_catalog_import_path(@import, open: open_section, anchor: open_section)
  end

  def find_import
    ItemCatalogImport.find(params[:id])
  end

  def find_item
    if params[:item_id].present?
      Item.find_by(id: params[:item_id])
    elsif params[:item_name].present?
      Item.find_by_name(params[:item_name].strip).first
    end
  end
end
