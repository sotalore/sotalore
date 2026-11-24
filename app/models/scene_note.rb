# frozen_string_literal: true

# A transcript of something Darren said about a scene while playing, which
# the companion records, transcribes on peregrin and adds through the API
# (Api::V1::SceneNotesController). Private: only root sees notes on the site,
# and only a token with the notes scope reads them, for the agent that
# writes the scene's narrative from them. Text only; the audio isn't kept.
#
# +client_id+ is the companion's own id for the note, unique per account, so
# a retry finds the note it already sent instead of adding it twice.
class SceneNote < ApplicationRecord
  MAX_TEXT = 20_000

  belongs_to :scene
  belongs_to :user

  scope :oldest_first, -> { order(:created_at, :id) }

  validates :text, presence: true, length: { maximum: MAX_TEXT }
  validates :recorded_at, presence: true
  validates :duration, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :transcriber, length: { maximum: 100 }
  validates :client_id, presence: true, length: { maximum: 100 }, uniqueness: { scope: :user_id }
end
