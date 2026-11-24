# frozen_string_literal: true

# Private transcript notes on scenes (see SceneNote): the companion adds them,
# and the agent that writes a scene's narrative reads them. Both need the
# notes scope; the read scope doesn't reach them.
class Api::V1::SceneNotesController < Api::BaseController
  before_action -> { require_scope!('notes') }

  # GET /notes: ?scene_id=, ?since= (added at or after), ?page=, ?per=
  def index
    authorize(SceneNote)
    notes = SceneNote.oldest_first.includes(:scene)
    notes = notes.where(scene_id: params[:scene_id]) if params[:scene_id].present?
    if params[:since].present?
      since = parse_time(params[:since])
      return error('since must be an ISO 8601 time') unless since
      notes = notes.where(created_at: since..)
    end
    render json: paged(:notes, notes) { note_json(_1) }
  end

  # POST /scenes/:scene_id/notes. A client_id this account already sent
  # returns that note (200) if it's the same scene and text, so a retry is
  # safe, and 409 if not.
  def create
    scene = Scene.find(params[:scene_id])
    authorize(SceneNote)
    if params[:recorded_at].present? && !parse_time(params[:recorded_at])
      return error('recorded_at must be an ISO 8601 time')
    end

    note = scene.notes.build(user: Current.user, **note_params)
    return render(json: note_json(note), status: :created) if note.save
    return already_sent(note) if note.errors.of_kind?(:client_id, :taken)
    render json: { errors: note.errors.full_messages }, status: :unprocessable_content
  rescue ActiveRecord::RecordNotUnique
    already_sent(note)
  end

  private

  def note_params
    { text: params[:text], recorded_at: params[:recorded_at].presence && parse_time(params[:recorded_at]),
      duration: params[:duration], transcriber: params[:transcriber].presence, client_id: params[:client_id] }
  end

  def already_sent(note)
    sent = SceneNote.find_by!(user: Current.user, client_id: note.client_id)
    if sent.scene_id == note.scene_id && sent.text == note.text
      render json: note_json(sent), status: :ok
    else
      render json: { error: "client_id #{note.client_id} was already sent with a different scene or text",
                     note: note_json(sent) }, status: :conflict
    end
  end

  def note_json(note)
    { id: note.id, scene: scene_ref(note.scene).merge(url: scene_url(note.scene)), text: note.text,
      recorded_at: note.recorded_at.iso8601, duration: note.duration, transcriber: note.transcriber,
      client_id: note.client_id, created_at: note.created_at.iso8601 }
  end

  # The time, or nil if +value+ isn't one.
  def parse_time(value)
    Time.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end

  def error(message)
    render json: { error: message }, status: :unprocessable_content
  end
end
