# frozen_string_literal: true

class Views::Adm::Styles::Tiles < Views::Base

  LOREM_1 = "In modern times authors often misinterpret the law as an ungyved ex-husband, when in actuality it feels more like a sunlit church. This could be, or perhaps authors often misinterpret the november as a mutant icicle, when in actuality it feels more like a gloomful fire."
  LOREM_2 = "A purest persian without quiets is truly a reason of reptant wines. Few can name an unchanged rock that isn't a valgus title. Framed in a different way, those locusts are nothing more than rifles. Nowhere is it disputed that the feather is a bengal."
  LOREM_3 = "Some helmless mailmen are thought of simply as cellos. An olive can hardly be considered a ferine pvc without also being a psychology. A windchime sees a boundary as an osmic pepper. The segments could be said to resemble outraged mexicos."

  def view_template
    render Views::Adm::Styles::Menu.new

    div(class: "my-8") do
      div(class: "w-full flex flex-row gap-x-8") do
        div(class: "basis-1_2") do
          render Components::Tile.new(heading: "Phlex Tile Heading", subheading: "The Sub") do
            p(class: "text-red-500") { "This is a paragraph" }
          end
        end

        div(class: "basis-1_2") do
          render Components::Tile.new(heading: "Second") do |tile|
            tile.controls do
              div(class: "border border-red-500") { "Control" }
            end
            p(class: "text-blue-500") { "This is a paragraph" }
          end
        end
      end
    end

    div(class: "flex flex-row flex-wrap") do
      div(class: "basis-1_2") do
        tile_with_heading("Tile With Heading") do
          p do
            plain "more_link_to: "
            more_link_to("#")
          end
          p { primary_button_to("Primary Button To", "#") }
          p { default_button_to("Default Button To", "#") }
        end
      end

      div(class: "basis-1_2") do
        tile do
          tile_heading("Tile with Controls", subheading: "subheading") do
            view_icon_to("#")
            edit_icon_to("#")
            destroy_icon_to("#")
          end
          tile_body do
            div(class: "prose") do
              p { "Just some text" }
              p { "and some more." }
            end
          end
        end
      end

      div(class: "basis-1_2") do
        tile do
          tile_heading(link_to("Heading as Link", "#"))
          tile_body do
            p { LOREM_2 }
            p { LOREM_3 }
          end
        end
      end
    end

    div(class: "flex flex-row") do
      div(class: "basis-1_2") do
        tile(:primary) do
          tile_heading("Default Tile", subheading: "Some thoughts") do
            default_button_to("view", "#")
            edit_button_to("edit", "#")
          end
          tile_body do
            p { LOREM_1 }
          end
        end

        %w[ info ].each do |type|
          tile(type) do
            tile_heading("#{type.capitalize} Tile")
            tile_body do
              p { LOREM_1 }
            end
          end
        end
      end

      div(class: "basis-1_2") do
        tile do
          tile_heading("Default Tile", subheading: "Some thoughts") do
            default_button_to("view", "#")
            edit_button_to("edit", "#")
          end
          tile_body do
            p { LOREM_1 }
          end
        end

        %w[ info ].each do |type|
          tile(type) do
            tile_heading("#{type.capitalize} Tile")
            tile_body(type) do
              p { LOREM_1 }
            end
          end
        end
      end
    end
  end

end
