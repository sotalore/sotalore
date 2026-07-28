# frozen_string_literal: true

class Views::Home::Roadmap < Views::Base

  def view_template
    div(class: "row") do
      div(class: "col-xs-6") do
        tile_with_heading("Credits", type: "primary") do
          div(class: "prose") do
            ul(class: "ml-8 list-disc") do
              li { "Huge thanks to Dorham Isycle for posting the Crafting Spreadsheet on the forums. That was my initial source for a lot of data." }
              li do
                plain "Thanks to "
                link_to("SotAwiki", "http://sotawiki.net/")
                plain " and "
                link_to("SotaCraft", "http://www.sotacraft.com/")
                plain " for all the inspiration."
              end
              li do
                plain "And, obviously, thanks to "
                link_to("Portalarium", "http://www.portalarium.com/")
                plain " for building us a world with which to tell our stories."
              end
            end
          end
        end

        tile_with_heading("Recent Site Updates", type: "success") do
          div(class: "prose") do
            ul(class: "ml-8 list-disc") do
              li { 'The top search bar will now activate with the hotkey "/".' }
              li { "Adding information to show when the data is confirmed." }
              li { "Adding ability for registered users to star recipes." }
              li { "Shopping list shows gold count of fuels." }
              li { "General improvement around recipe UI." }
              li { "General improvement around item UI." }
              li { "Colors are hard, trying to figure out a color scheme. Design skills are sorely lacking." }
              li { "Adding comments and tracking changes to things." }
              li { "Better UI around items and recipes." }
              li { "We have a new name! SotAStuff is dead, long live SotA Lore!" }
              li { "Better item detail on recipes for fuel, tools, prices, gathering." }
              li { "Fix bug where recipes referred to themselves (yes, there is a recipe that takes its output as input)." }
              li { "Some images and icons for a little bit of style." }
              li { "The shopping list can now be adjusted for multiple results." }
              li { "Trying to show the complete shopping list to make something from scratch (including all sub recipes.)" }
            end
          end
        end
      end

      div(class: "col-xs-6") do
        tile_with_heading("Site Roadmap", type: "info") do
          div(class: "prose") do
            blockquote { "A number of things I'd love to do with this site, in no particular order." }

            h4 { "Recipe Stuff" }
            ul(class: "ml-8 list-disc") do
              li { "Allow avatars to create a recipe book of their own to track what recipes they have" }
              li { "Allow avatars to create a workorder with several recipes to track the costs of the entire work order" }
              li { "Allow avatars to add 'vendors', to advertise the wares they have for sale (integration with sotamap would be cool)" }
              li { "Get more information about minimum skills and recipe sources" }
              li { "Have avatars find vendors, to go and buy from them" }
            end

            h4 { "Quests" }
            ul(class: "ml-8 list-disc") do
              li { "Allow avatars to enter and find quest information" }
              li { "Yeah, all those things :)" }
            end

            h4 { "General" }
            ul(class: "ml-8 list-disc") do
              li { "Give proper credit to data and image sources (especially copyright to Portalarium)" }
              li { "Develop APIs to allow other developers to create tools like this" }
            end
          end
        end
      end
    end
  end

end
