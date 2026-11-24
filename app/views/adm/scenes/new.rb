# frozen_string_literal: true

class Views::Adm::Scenes::New < Views::Base

  def initialize(scene:)
    @scene = scene
  end

  def view_template
    div(class: 'm-2 p-4 max-w-xl bg-white dark:bg-grey-800') do
      h1(class: 'mb-4 text-2xl font-bold') { 'Add New Scene' }
      render Views::Adm::Scenes::Form.new(scene: @scene)
    end
  end

end
