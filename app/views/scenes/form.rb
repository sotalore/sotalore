# frozen_string_literal: true

class Views::Scenes::Form < Views::Scenes::Base
  include Grav::Views::Forms::Base

  def initialize(scene:)
    super(model: scene)
  end

  def view_template
    super do
      text_field(:name, autofocus: true)

      select_field(:level_id) do |select|
        select.options(Scene::LEVELS, display: :first, value: :last, include_blank: :blank)
      end
      checkbox_field(:level_plus)

      select_field(:scene_type_id) do |select|
        select.options(Scene::SCENE_TYPES, display: :first, value: :last, include_blank: :blank)
      end

      select_field(:region_id) do |select|
        select.options(Scene::REGIONS, display: :first, value: :last, include_blank: :blank)
      end

      select_field(:parent_id) do |select|
        select.options(parent_options, display: :first, value: :last, include_blank: :blank)
      end

      checkbox_field(:pvp)
      number_field(:sota_map_id)
      number_field(:sota_map_parent_poi_id)

      form_actions do
        cancel_button
        submit_button
      end
    end
  end

  private

  def parent_options
    Scene.by_name_overworld_first.map { |s| [ s.name, s.id ] }
  end

end
