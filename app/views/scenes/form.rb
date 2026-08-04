# frozen_string_literal: true

class Views::Scenes::Form < Views::Form

  def initialize(scene:)
    @scene = scene
  end

  def view_template
    render form_builder(model: @scene) do |f|
      f.text_field(:name, autofocus: true)

      f.select_field(:level_id) do |select|
        select.options(Scene::LEVELS, display: :first, value: :last, include_blank: :blank)
      end
      f.checkbox_field(:level_plus)

      f.select_field(:scene_type_id) do |select|
        select.options(Scene::SCENE_TYPES, display: :first, value: :last, include_blank: :blank)
      end

      f.select_field(:region_id) do |select|
        select.options(Scene::REGIONS, display: :first, value: :last, include_blank: :blank)
      end

      f.select_field(:parent_id) do |select|
        select.options(parent_options, display: :first, value: :last, include_blank: :blank)
      end

      f.checkbox_field(:pvp)
      f.number_field(:sota_map_id)
      f.number_field(:sota_map_parent_poi_id)

      f.form_actions do
        f.cancel_button
        f.submit_button
      end
    end
  end

  private

  def parent_options
    Scene.by_name_overworld_first.map { |s| [ s.name, s.id ] }
  end

end
