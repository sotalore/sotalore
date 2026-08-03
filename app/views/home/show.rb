# frozen_string_literal: true

class Views::Home::Show < Views::Base

  def view_template
    div(class: "grid grid-cols-2") do
      div(class: "p-2 md:p-4 col-span-2 md:col-span-1") do
        tile("info") do
          tile_heading("Updates", type: "info")
          tile_body do
            p { strong { "Things are quiet." } }

            p do
              plain "Not much has been going on here, although, we do continue "
              plain "to do maintenance on the app, and try and stay on top of new recipes."
            end
          end
        end

        div(class: 'm-tile') do
          render Components::Comments::Subject.new(subject: :front_page)
        end
      end

      div(class: "p-2 md:p-4 col-sm-6 col-span-2 md:col-span-1") do
        tile_with_heading("Contact Us") do
          p { strong { "Thanks for visiting SotaLore!" } }

          p do
            plain "This site is a constant work in progress. If you'd like to help in any way, "
            plain "or just provide feedback, you can reach out to Gravidy. You can leave me a "
            plain "note on the "
            link_to("SotA official forums", "https://www.shroudoftheavatar.com/forum/index.php?members/gravidy.6235/", target: "_blank")
            plain "."
          end
        end

        tile_with_heading("Here's the latest recipes") do
          Recipe.order(id: :desc).first(5).each do |recipe|
            render Components::Recipes::Card.new(recipe: recipe)
          end
        end
      end
    end
  end

end
