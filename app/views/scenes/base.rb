# frozen_string_literal: true

class Views::Scenes::Base < Views::Base

  def scene_level(scene)
    return unless scene
    "#{scene.level}#{scene.level_plus ? '+' : ''}"
  end

end
