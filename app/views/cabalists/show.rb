# frozen_string_literal: true

class Views::Cabalists::Show < Views::Base

  def view_template
    layout_main_content do
      notice_info do
        plain "Testing has shows that the cabalist sieges don't appear (or end) consistently. "
        plain "A difference of up to a couple minutes has been seen. If you have any insight, "
        plain "or see a pattern to the differences, please "
        link_to("post on the forums", Sota.forum_thread)
        plain ". Thanks!"
      end

      tile do
        tile_heading("Cabalist Sieges")

        tile_body do
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

      notice_info do
        plain "There's more details about the astronomy workings on a page about "
        link_to("time", time_path)
        plain "."
      end
    end
  end

end
