# frozen_string_literal: true

class Views::Farmings::Show < Views::Farmings::Base

  def view_template
    h1 { "Farming Planner" }

    tile do
      tile_heading("Watering Calculator")
      tile_body do
        render Views::Farmings::Planner.new
      end
    end

    tile_with_heading("Farming Information") do
      div(class: "row") do
        div(class: "col-md-4") do
          p do
            plain "Seeds are grouped by the time it takes to fully grow. There are three " \
              "different speeds, which take 24 hours, 48 hours and 72 hours (a " \
              "greenhouse halves the time, planting inside is a 10-fold increase). " \
              "These seeds also happen to be grouped by price, as shown in this table."
          end
        end

        div(class: "col-md-8") do
          table(class: "Table") do
            thead do
              tr do
                th { "Cost" }
                th { "Outside Time" }
                th { "Greenhouse Time" }
                th { "Inside Time" }
              end
            end
            tbody do
              tr do
                th { "6-10 gold" }
                td { "24 hours" }
                td { "12 hours" }
                td { "240 hours" }
              end
              tr do
                th { "16 gold" }
                td { "48 hours" }
                td { "24 hours" }
                td { "480 hours" }
              end
              tr do
                th { "30 gold" }
                td { "72 hours" }
                td { "36 hours" }
                td { "720 hours" }
              end
            end
          end
        end
      end
    end

    tile_with_heading("Watering Information") do
      p do
        plain "For maximum yield, seeds have to be watered a total of four times, at the appropriate time. The "
        strong { "first watering" }
        plain " occurs when the seed is planted. Subsequent waterings occer in every "
        em { "third" }
        plain " of the growing time. The first third starts immediately after planting, so the easiest time to do the "
        strong { "second watering" }
        plain " is immediately following planting."
      end

      table(class: "Table") do
        thead do
          tr do
            th { "Speed" }
            th { "Second Watering" }
            th { "Third Watering" }
            th { "Fourth Watering" }
            th { "Harvest" }
          end
        end
        tbody do
          tr do
            td { "Quick" }
            td { "0 to 8 hours" }
            td { "8 to 16 hours" }
            td { "16 to 24 hours" }
            td { "After 24 hours" }
          end
          tr do
            td { "Medium" }
            td { "0 to 16 hours" }
            td { "16 to 32 hours" }
            td { "32 to 48 hours" }
            td { "After 48 hours" }
          end
          tr do
            td { "Slow" }
            td { "0 to 24 hours" }
            td { "24 to 48 hours" }
            td { "48 to 72 hours" }
            td { "After 72 hours" }
          end
        end
      end

      p { "Remember that a greenhouse halves these times." }
    end

    tile do
      tile_heading("Seeds")
      tile_body do
        seeds_section
      end
    end
  end

  private

  def seeds_section
    notice_info do
      plain "When known, the expected average yield from complete watering is shown in "
      em { "(parentheses)" }
      plain "."
    end

    seeds = Item.use_is_seed.all.order(:price, "lower(name)").to_a

    div(class: "flex flex-row flex-wrap gap-2") do
      seed_column("Quick Growing Seeds", seeds.select { |s| s.price && s.price < 16 })
      seed_column("Medium Growing Seeds", seeds.select { |s| s.price == 16 })
      seed_column("Slow Growing Seeds", seeds.select { |s| s.price && s.price > 16 })
    end
  end

  def seed_column(heading, seeds)
    div(class: "flex-grow min-w-fit") do
      h3 { heading }
      ul do
        seeds.each do |seed|
          seed_row(seed)
        end
      end
    end
  end

  def seed_row(seed)
    li(class: "my-1") do
      if policy(Item).edit?
        edit_icon_to(edit_item_path(seed), size: :small)
        whitespace
      end
      link_to(seed, seed)
      if seed.yield.present?
        whitespace
        em { "(#{seed.yield})" }
      end
      whitespace
      item_price_tag(seed)
    end
  end

end
