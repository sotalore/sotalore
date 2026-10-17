# frozen_string_literal: true

# A gathering node is in a scene (from a finds import).
class SceneNode < ApplicationRecord
  belongs_to :scene, optional: false
  belongs_to :gathering_node, optional: false
end
