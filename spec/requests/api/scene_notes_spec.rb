require 'rails_helper'

RSpec.describe "Api::V1 scene notes", type: :request do
  let(:admin) { create(:user, :root) }
  let(:ai)    { User.create_ai_account!(name: 'Companion') }
  let!(:ravenswood) { create(:scene, name: 'West Ravenswood') }
  let!(:valeway)    { create(:scene, name: 'South Valeway') }

  def headers(scopes = %w[ read notes ], user: ai)
    { 'Authorization' => "Bearer #{ApiToken.issue!(user: user, name: 't', scopes: scopes, created_by: admin).last}" }
  end

  def note_params(**overrides)
    { text: 'The ruins by the river have a locked chest.', recorded_at: '2026-11-23T10:15:00-08:00',
      duration: 42, transcriber: 'whisper-large-v3', client_id: 'note-1' }.merge(overrides)
  end

  def add_note(scene, auth = headers, **overrides)
    post api_v1_scene_notes_path(scene), params: note_params(**overrides), headers: auth, as: :json
  end

  describe 'POST /scenes/:id/notes' do
    it 'adds the note, recording who sent it' do
      add_note(ravenswood)
      expect(response).to have_http_status(:created)
      note = ravenswood.notes.sole
      expect(note).to have_attributes(user: ai, duration: 42, transcriber: 'whisper-large-v3', client_id: 'note-1',
                                      recorded_at: Time.iso8601('2026-11-23T10:15:00-08:00'))
      expect(response.parsed_body).to include(
        'id' => note.id, 'scene' => include('id' => ravenswood.id, 'url' => scene_url(ravenswood)),
        'text' => 'The ruins by the river have a locked chest.', 'duration' => 42, 'client_id' => 'note-1'
      )
    end

    it 'returns the note already sent for a retry, and refuses a different note under the same client_id' do
      auth = headers
      add_note(ravenswood, auth)
      id = response.parsed_body['id']

      add_note(ravenswood, auth)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq id

      add_note(ravenswood, auth, text: 'Something else')
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body['note']['id']).to eq id

      add_note(valeway, auth)
      expect(response).to have_http_status(:conflict)
      expect(SceneNote.count).to eq 1
    end

    it "lets another account use the same client_id" do
      add_note(ravenswood)
      add_note(ravenswood, headers(user: User.create_ai_account!(name: 'Other')))
      expect(response).to have_http_status(:created)
    end

    it 'refuses a note without text or a time, or too long, or with a fractional duration' do
      auth = headers
      add_note(ravenswood, auth, text: '')
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['errors']).to include("Text can't be blank")

      add_note(ravenswood, auth, recorded_at: 'yesterday')
      expect(response.parsed_body['error']).to match(/recorded_at/)

      add_note(ravenswood, auth, recorded_at: nil)
      expect(response).to have_http_status(:unprocessable_content)

      add_note(ravenswood, auth, text: 'x' * (SceneNote::MAX_TEXT + 1))
      expect(response).to have_http_status(:unprocessable_content)

      add_note(ravenswood, auth, duration: 12.5)
      expect(response).to have_http_status(:unprocessable_content)
      expect(SceneNote.count).to eq 0
    end

    it "keeps the transcript out of the logs" do
      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      expect(filter.filter(note_params)).to include(text: '[FILTERED]', client_id: 'note-1')
    end

    it 'needs the notes scope and a scene that exists' do
      add_note(ravenswood, headers(%w[ read images ]))
      expect(response).to have_http_status(:forbidden)

      add_note(Scene.new(id: 0))
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /notes' do
    def notes(auth = headers, **params)
      get api_v1_notes_path, params: params, headers: auth
      response.parsed_body['notes']&.map { _1['text'] }
    end

    it "lists notes oldest first, for one scene or added since a time" do
      create_note(ravenswood, 'first', '10:00')
      create_note(valeway, 'second', '11:00')
      create_note(ravenswood, 'third', '12:00')
      auth = headers

      expect(notes(auth)).to eq %w[ first second third ]
      expect(response.parsed_body['page']).to include('total_count' => 3)
      expect(notes(auth, scene_id: ravenswood.id)).to eq %w[ first third ]
      expect(notes(auth, since: '2026-11-23T11:00:00-08:00')).to eq %w[ second third ]

      notes(auth, since: 'soon')
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "isn't open to a token with only read" do
      expect(notes(headers(%w[ read ]))).to be_nil
      expect(response).to have_http_status(:forbidden)
    end

    def create_note(scene, text, at)
      time = Time.zone.parse("2026-11-23 #{at}")
      scene.notes.create!(user: ai, text: text, recorded_at: time, created_at: time, client_id: text)
    end
  end
end
