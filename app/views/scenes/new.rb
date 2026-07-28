# frozen_string_literal: true

class Views::Scenes::New < Views::Scenes::Base

  def initialize(scene:)
    @scene = scene
  end

  def view_template
    layout_main_content(size: :sm) do
      tile_with_heading("Add New Scene") do
        render Views::Scenes::Form.new(scene: @scene)
      end
    end
  end

end
