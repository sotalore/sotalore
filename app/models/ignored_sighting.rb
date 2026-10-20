# frozen_string_literal: true

# A name a finds file lists as targeted in a scene but never fought (its
# "seen" list; see GameFinds) that an admin decided isn't a creature there:
# an NPC, a player, someone's pet. Later finds imports leave it out of
# review in that scene.
class IgnoredSighting < ApplicationRecord
  belongs_to :scene, optional: false

  validates :name, presence: true, uniqueness: { scope: :scene_id, case_sensitive: false }
end
