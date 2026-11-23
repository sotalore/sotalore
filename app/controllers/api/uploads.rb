# frozen_string_literal: true

# Uploading the admin plugin's export files (see sotalore/sladmin
# EXPORT-FORMAT.md) as imports, as the ADM import pages do: the upload only
# makes the import, which root reviews and applies on the site. The file comes
# as a multipart "file" and must say its "type" (plugin 0.7.1 and later), so
# one sent to the wrong endpoint is refused. The same file sent again returns
# the import it already made, so a client can safely retry.
module Api::Uploads

  MAX_UPLOAD_SIZE = 10.megabytes

  # A file's "type" => the endpoint that takes it.
  ENDPOINTS = {
    'recipes' => 'recipe_imports', 'items' => 'item_catalog_imports', 'finds' => 'finds_imports'
  }.freeze

  private

  # Makes an import of +model+ from the uploaded file, which must hold
  # +type+, and renders it as the block makes it: 201, or 200 for a file
  # already uploaded.
  def create_upload(model, type)
    file = params[:file]
    unless file.respond_to?(:read)
      render json: { error: 'Send the export file as a multipart "file" field' }, status: :bad_request
      return
    end
    if file.size > MAX_UPLOAD_SIZE
      render json: { error: "The file is over #{MAX_UPLOAD_SIZE / 1.megabyte} MB" }, status: :content_too_large
      return
    end

    json = file.read
    if (import = model.find_by_content(json))
      render json: yield(import), status: :ok
      return
    end
    check_upload_type!(json, type)
    import = model.create_from_json!(json, filename: file.original_filename, user: Current.user)
    render json: yield(import), status: :created
  rescue JSON::ParserError, ArgumentError => e
    render json: { error: "Couldn't import that: #{e.message.truncate(200)}" }, status: :unprocessable_content
  end

  def check_upload_type!(json, type)
    data = JSON.parse(json)
    found = data.is_a?(Hash) ? data['type'].presence : nil
    return if found == type

    raise ArgumentError,
          if found.nil? then 'the file has no "type"; export it again with the current plugin'
          elsif ENDPOINTS[found] then "that file holds #{found}; send it to POST /api/v1/#{ENDPOINTS[found]}"
          else %(the site doesn't take "#{found}" files)
          end
  end

end
