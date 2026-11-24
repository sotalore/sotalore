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
        default_button_to("Manage", adm_scenes_path) if policy(Scene).manage?
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
      end

      tbody do
        @scenes.each do |scene|
          tr do
            td { link_to(scene.name, scene) }
            td { scene_level(scene) }
            td { render(Components::Icons::BadgeCheck.new) if scene.pvp }
            td { scene.region }
            td { scene.scene_type }
          end
        end
      end
    end

    paginate @scenes
  end

end
