# frozen_string_literal: true

# Uploading item catalogs (sotalore-item-catalog.json; see Api::Uploads).
class Api::V1::ItemCatalogImportsController < Api::BaseController
  include Api::Uploads

  before_action -> { require_scope!('upload') }

  def create
    authorize(ItemCatalogImport)
    create_upload(ItemCatalogImport, 'items') do |import|
      { id: import.id, filename: import.filename, api_version: import.api_version,
        plugin_version: import.plugin_version, created_at: import.created_at.iso8601,
        items: import.catalog.entries.size, review_url: adm_item_catalog_import_url(import) }
    end
  end
end
