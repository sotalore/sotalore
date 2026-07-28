# frozen_string_literal: true

class Views::Scenes::FilterForm < Views::Scenes::Base
  include Grav::Views::Forms::Base

  def initialize(filter:)
    super(model: filter, style: :inline)
    simple_get_form!
  end

  def form_action
    scenes_path
  end

  def view_template
    super do
      select_field(:level_id) do |select|
        select.options(Scene::LEVELS, display: :first, value: :last, include_blank: "-- all levels --")
      end

      select_field(:pvp) do |select|
        select.options([ [ "PVP", 0 ], [ "Not PVP", 1 ] ], display: :first, value: :last, include_blank: "-- any --")
      end

      select_field(:region_id) do |select|
        select.options(Scene::REGIONS, display: :first, value: :last, include_blank: "-- all regions --")
      end

      select_field(:scene_type_id) do |select|
        select.options(Scene::SCENE_TYPES, display: :first, value: :last, include_blank: "-- all scene types --")
      end

      submit_button("Filter", class: "h-8")
    end
  end

end
