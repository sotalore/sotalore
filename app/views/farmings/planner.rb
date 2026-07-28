# frozen_string_literal: true

class Views::Farmings::Planner < Views::Farmings::Base

  def view_template
    div(id: "FarmingPlanner", data: { controller: "farming", "farming-export-calendar-base-url-value": farming_calendar_path }) do
      seed_type_form
      plan_table
      export_section
    end
  end

  private

  def seed_type_form
    form(class: "flex flex-inline flex-wrap gap-2 border-b border-dashed border-grey-400 mb-2 pb-2") do
      div do
        label(class: "font-semibold") do
          plain "What type of seed?"
          whitespace
          select(class: "font-normal form-select", data: { action: "change->farming#updateSeedTime" }) do
            options_for_select([ [ "Quick", 24 / 3 ], [ "Medium", 48 / 3 ], [ "Slow", 72 / 3 ] ])
          end
        end
      end
      div do
        label(class: "font-semibold") do
          plain "Planting Location:"
          whitespace
          select(class: "font-normal form-select", data: { action: "change->farming#updateLocationFactor" }) do
            options_for_select([ [ "Normal / Outside (1.0)", 1 / 1 ], [ "Greenhouse (2.0)", "0.5" ], [ "Inside (0.1)", "10.0" ] ])
          end
        end
      end
    end
  end

  def plan_table
    div(class: "farming-plan-table") do
      plan_row("Watering Window:", data: { "farming-target": "windowTime" })

      plan_row("Planting at:", data: { "farming-target": "startTime" }) { local_time(Time.zone.now) }

      plan_row("First Water:") { em { "with planting" } }

      plan_row("Second Water:") { em { "after planting" } }

      plan_row("Third Water:", data_class: "watering-window") do
        div(class: "water-start", data: { "farming-target": "segment1" }) { local_time(8.hours.from_now) }
        div(class: "water-end", data: { "farming-target": "segment2" }) { local_time(16.hours.from_now) }
      end

      plan_row("Fourth Water:", data_class: "watering-window") do
        div(class: "water-start", data: { "farming-target": "segment2" }) { local_time(16.hours.from_now) }
        div(class: "water-end", data: { "farming-target": "endTime" }) { local_time(24.hours.from_now) }
      end

      plan_row("Harvest after:", data: { "farming-target": "endTime" }) { local_time(24.hours.from_now) }
    end
  end

  def plan_row(label_text, data: {}, data_class: nil)
    div(class: "farming-plan-label") { label_text }
    div(class: [ "farming-plan-data", data_class ], data: data) { yield if block_given? }
  end

  def export_section
    div(class: "align-baseline border-t pt-2 flex flex-wrap gap-2") do
      label(class: "font-semibold self-center") { "Calendar:" }
      input(class: "form-input", type: "text", value: "SOTA Farming", maxlength: "80", data: { "farming-target": "exportName" })
      div(class: "self-center") do
        a(class: "inline-block align-baseline Button Button--primary", href: "#", data: { "farming-target": "exportCalendar" }) { "Download" }
        whitespace
        a(class: "inline-block align-baseline Button Button--primary", href: "#",
          data: { "farming-target": "copyCalendarUrl", action: "click->farming#copyCalendarUrl" }) { "Copy Link" }
        whitespace
        span(class: "text-green-500 opacity-0 hidden transition-all duration-500", data: { "farming-target": "copyCalendarUrlMessage" }) do
          plain "Copied"
          whitespace
          render_icon("badge_check")
        end
        whitespace
        a(class: "inline-block align-baseline", href: "#", data: { action: "click->farming#showCalendarHelp" }) { "what is this?" }
      end
      div(class: "basis-full hidden", data: { "farming-target": "calendarHelp" }) do
        notice_info do
          p do
            plain "This will create a calendar that you can import into your calendar app of choice. " \
              "If it's easier to use a URL/link to import, you can "
            strong { "copy the link" }
            plain " above. Otherwise, you can "
            strong { "download" }
            plain ' the "ICS" file and import it into your calendar app.'
          end

          p do
            plain "We're not sure how well this is going to work for all the different calendaring " \
              "apps out there. So, please provide any and all feedback you have."
          end
        end
      end
    end
  end

end
