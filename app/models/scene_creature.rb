# frozen_string_literal: true

# A creature lives in a scene (from a finds import), with the range of
# levels seen there, when the game let them be read.
class SceneCreature < ApplicationRecord
  belongs_to :scene, optional: false
  belongs_to :creature, optional: false

  # Widens the level range to take in +min+..+max+.
  def widen(min, max)
    self.level_min = [ level_min, min ].compact.min
    self.level_max = [ level_max, max ].compact.max
  end

  def levels
    return if level_min.nil? && level_max.nil?
    level_min == level_max ? level_min.to_s : "#{level_min}–#{level_max}"
  end
end
