# frozen_string_literal: true

# An item can be found in a scene (from a finds import): looted, bought,
# gathered or otherwise gained there. Presence only, not how often.
class SceneFind < ApplicationRecord
  belongs_to :scene, optional: false
  belongs_to :item, optional: false
end
