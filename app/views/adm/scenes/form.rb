# frozen_string_literal: true

# Adding or editing a scene's details, in ADM.
class Views::Adm::Scenes::Form < Views::Form

  def initialize(scene:)
    @scene = scene
  end

  def view_template
    cancel = @scene.persisted? ? adm_scene_path(@scene) : adm_scenes_path
    render form_builder(model: [ :adm, @scene ], cancel_url: cancel) do |f|
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
