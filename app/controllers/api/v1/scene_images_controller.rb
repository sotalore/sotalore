# frozen_string_literal: true

# Adding an image (a screenshot) to a scene's gallery, sent as a multipart
# "file". It goes live at once, as when root adds one on the scene's page; the
# client asks its user before sending. The same file sent to the same scene
# again returns the image already there, so a client can retry. Who sent it
# (and +taken_at+, if given) is kept in the blob's custom metadata.
class Api::V1::SceneImagesController < Api::BaseController
  before_action -> { require_scope!('images') }

  MAX_SIZE = 20.megabytes
  CONTENT_TYPES = %w[ image/png image/jpeg image/webp ].freeze

  def create
    scene = Scene.find(params[:scene_id])
    authorize(scene, :add_image?)
    file = params[:file]
    return error('Send the image as a multipart "file" field', :bad_request) unless file.respond_to?(:read)
    return error("The image is over #{MAX_SIZE / 1.megabyte} MB", :content_too_large) if file.size > MAX_SIZE

    bytes = file.read
    if (image = existing_image(scene, bytes))
      render json: image_json(image), status: :ok
      return
    end

    content_type = Marcel::MimeType.for(StringIO.new(bytes))
    return error('The image must be PNG, JPEG or WebP', :unprocessable_content) unless content_type.in?(CONTENT_TYPES)
    taken_at = params[:taken_at].presence && parse_time(params[:taken_at])
    return error('taken_at must be an ISO 8601 time', :unprocessable_content) if taken_at == false

    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(bytes), filename: file.original_filename.presence || 'screenshot', content_type: content_type,
      identify: false, metadata: { custom: { uploaded_by_id: Current.user.id, taken_at: taken_at&.iso8601 }.compact }
    )
    scene.images.attach(blob)
    render json: image_json(scene.images_attachments.find_by!(blob: blob)), status: :created
  end

  private

  # Active Storage's checksum is the file's MD5, in base 64 (see
  # ActiveStorage::Blob#compute_checksum_in_chunks).
  def existing_image(scene, bytes)
    scene.images_attachments.joins(:blob)
         .find_by(active_storage_blobs: { checksum: OpenSSL::Digest::MD5.base64digest(bytes) })
  end

  def image_json(image)
    { id: image.id, scene: scene_ref(image.record).merge(url: scene_url(image.record)),
      url: rails_blob_url(image), preview_url: rails_representation_url(image.variant(:preview)),
      content_type: image.blob.content_type, byte_size: image.blob.byte_size, created_at: image.created_at.iso8601 }
  end

  # The time, or false if +value+ isn't one.
  def parse_time(value)
    Time.iso8601(value)
  rescue ArgumentError
    false
  end

  def error(message, status)
    render json: { error: message }, status: status
  end
end
