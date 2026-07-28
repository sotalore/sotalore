# frozen_string_literal: true

class Components::Plantings::Card < Components::Base

  include Phlex::Rails::Helpers::SimpleFormat

  def initialize(planting:)
    @planting = planting
  end

  def view_template
    tile do
      tile_heading(@planting.seed) { destroy_icon_to(@planting) }
      tile_body do
        if @planting.notes.present?
          notice_info { simple_format(@planting.notes) }
        end

        p do
          plain "Planted at: #{l(@planting.planted_at)}"
          whitespace
          em { "- #{@planting.location_type}" }
        end

        growing_chart
      end
    end
  end

  private

  def growing_chart
    days_of_growing = @planting.days_of_growing
    day_width = 100.0 / @planting.total_calendar_days.to_f

    div(class: "flex flex-col justify-between") do
      div(class: "flex flex-row") do
        days_of_growing.each do |date|
          div(class: "text-center py-2 mt-2 border-2 border-grey-400 border-r-0 last:border-r-2", style: "width: #{day_width}%") do
            l(date, format: :watering_calendar)
          end
        end
      end

      div(class: "flex flex-row items-end") do
        div(style: "width: #{@planting.buffer_width}%") do
          div(class: "bg-transparent -mr-4 text-sm text-right") { l(@planting.planted_at, format: :watering_step) }
        end
        @planting.step_end_times.each_with_index do |time, idx|
          div(style: "width: #{@planting.step_width}%") do
            border_class = idx == Planting::WATERING_STEPS - 1 ? "border-r-2" : "border-r-0"
            div(class: "border-2 border-t-0 border-grey-400 bg-grey-100 text-center text-xs md:text-sm #{border_class}") { "Water #{idx + 1}" }
            div(class: "bg-transparent -mr-4 text-sm text-right") { l(time, format: :watering_step) }
          end
        end
      end
    end
  end

end
