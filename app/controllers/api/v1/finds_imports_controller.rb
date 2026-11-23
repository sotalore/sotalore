# frozen_string_literal: true

# Uploading finds files (sotalore-scene-finds.json; see Api::Uploads).
class Api::V1::FindsImportsController < Api::BaseController
  include Api::Uploads

  before_action -> { require_scope!('upload') }

  def create
    authorize(FindsImport)
    create_upload(FindsImport, 'finds') do |import|
      { id: import.id, filename: import.filename, api_version: import.api_version,
        plugin_version: import.plugin_version, created_at: import.created_at.iso8601,
        scenes: import.finds.scenes.size, review_url: adm_finds_import_url(import) }
    end
  end
end
