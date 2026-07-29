# frozen_string_literal: true

class Views::Scenes::Index < Views::Scenes::Base

  def initialize(scenes:, filter:)
    @scenes = scenes
    @filter = filter
  end

  def view_template
    page_title("Scenes")

    tile do
      tile_heading("All Scenes") do
        new_button_to("New Scene", new_scene_path) if policy(Scene).new?
      end

      tile_body do
        render Views::Scenes::FilterForm.new(filter: @filter)
        scenes_table
      end
    end
  end

  private

  def scenes_table
    table(class: "Table") do
      thead do
        th { "Name" }
        th { "Tier" }
        th { "PVP" }
        th { "Region" }
        th { "Type" }
        th { } if policy(Scene).edit?
      end

      tbody do
        @scenes.each do |scene|
          tr do
            td { link_to(scene.name, scene) }
            td { scene_level(scene) }
            td { render(Components::Icons::BadgeCheck.new) if scene.pvp }
            td { scene.region }
            td { scene.scene_type }
            if policy(Scene).edit?
              td(class: "u-textRight") { edit_icon_to(edit_scene_path(scene)) }
            end
          end
        end
      end
    end

    paginate @scenes
  end

end
