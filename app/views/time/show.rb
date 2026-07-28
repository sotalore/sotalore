# frozen_string_literal: true

class Views::Time::Show < Views::Base

  def view_template
    layout_main_content do
      notice_warning do
        plain "This is a work in progress. I believe things are accurate, but "
        plain "I'm still trying to confirm that belief. If you see any errors, "
        em { "please" }
        plain " let me know! On the "
        link_to("Home Page", root_path)
        plain ", there is a few ways to contact me."
      end

      tile do
        tile_body do
          h2 do
            plain "New Brittania Time:"
            span(data: { controller: "time" })
          end
        end
      end

      tile do
        tile_body do
          h2(data: { controller: "orbit", "orbit-period-value": Astronomy::DAEDALUS_ORBITAL_PERIOD }) do
            plain "Daedalus Position:"
            small(class: "font-normal") do
              span(data: { "orbit-target": "position" })
              span(class: "text-sm italic", data: { "orbit-target": "note" })
            end
          end
        end
      end

      tile do
        tile_body do
          h2 { "Cabalists" }

          table(class: "Table") do
            thead(class: "border-b-2 border-grey-300") do
              th { }
              th { "Current City" }
              th { "Symbol" }
              th { "Virtue" }
              th(class: "text-right") { "Remaining" }
              th { "Next City" }
            end

            Astronomy::PLANETS.each do |planet, info|
              tr(class: "hover:bg-grey-100", data: {
                controller: "cabalist",
                "cabalist-period-value": info[:orbital_period],
                "cabalist-offset-value": info[:offset]
              }) do
                td(class: "font-bold pr-2") { info[:cabalist].to_s.titleize }
                td(data: { "cabalist-target": "currentCity" })
                td(class: "text-sm", data: { "cabalist-target": "symbol" })
                td(class: "text-sm", data: { "cabalist-target": "virtue" })
                td(class: "text-right", data: { "cabalist-target": "timeRemaining" })
                td(data: { "cabalist-target": "nextCity" })
              end
            end
          end
        end
      end

      tile do
        tile_body do
          h2 { "Planet Positions:" }

          table(class: "Table") do
            thead(class: "border-b-2 border-grey-300") do
              th { "Planet" }
              th { "Position" }
              th { "Visible?" }
              th(class: "text-right") { "Zenith in" }
              th { "Color" }
              th { "Orbital Period" }
              th { "Cabalist" }
            end

            Astronomy::PLANETS.each do |planet, info|
              tr(class: "hover:bg-grey-100", data: { controller: "orbit", "orbit-period-value": info[:orbital_period] }) do
                td(class: "font-bold") { planet.to_s.titleize }
                td { span(class: "mr-4", data: { "orbit-target": "position" }) }
                td { span(class: "text-right text-sm italic", data: { "orbit-target": "note" }) }
                td(class: "text-right", data: { "orbit-target": "timeToZenith" })
                td(class: "planet-#{info[:color]}") { info[:color] }
                td { plain "#{info[:orbital_period]} days" }
                td { info[:cabalist] }
              end
            end
          end
        end
      end

      tile do
        tile_body do
          h2 { "Constellations:" }

          table(class: "Table") do
            thead(class: "border-b-2 border-grey-300") do
              th { "Constellation" }
              th { "Position (arc)" }
              th(class: "text-right") { "Zenith in" }
              th { "Visible?" }
              th { "City" }
              th { "Virtue" }
            end

            Constellations::ALL.each do |constellation, info|
              tr(class: "hover:bg-grey-100", data: { controller: "constellation", "constellation-offset-value": info[:offset] }) do
                td(class: "font-buld") { constellation.to_s.titleize }
                td(data: { "constellation-target": "position" })
                td(class: "text-right", data: { "constellation-target": "timeToZenith" })
                td(class: "text-sm italic", data: { "constellation-target": "note" })
                td(class: "text-sm") { info[:city] }
                td(class: "text-sm") { info[:virtue] }
              end
            end
          end
        end
      end
    end
  end

end
