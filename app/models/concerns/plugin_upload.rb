# frozen_string_literal: true

# An import made from an uploaded plugin file, which keeps the file's SHA-256
# so the same file uploaded again can be found (see Api::Uploads).
module PluginUpload
  extend ActiveSupport::Concern

  class_methods do
    def content_digest(json)
      OpenSSL::Digest::SHA256.hexdigest(json)
    end

    # The import made from exactly this file, if there is one.
    def find_by_content(json)
      where(content_digest: content_digest(json)).order(:id).first
    end
  end
end
