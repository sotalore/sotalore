# frozen_string_literal: true

require "icalendar/tzinfo"

class FarmingCalendarsController < ApplicationController
  skip_after_action :verify_authorized

  def show
    Time.use_zone("UTC") do
      start_time = Time.zone.parse(params[:start]).utc
      base_time = Integer(params[:seedTime])
      location_factor = Float(params[:locationFactor])
      phase_length = base_time * location_factor
      name = params[:name]
      name = name.gsub(/[^0-9A-Za-z\-_ ]/, '')
      name = 'SOTA Farming' if name.blank?

      cal = Icalendar::Calendar.new
      timezone = TZInfo::Timezone.get("UTC").ical_timezone(start_time)
      cal.add_timezone(timezone)
      add_event(cal, "#{name} Planting / Phase 1", start_time)
      add_event(cal, "#{name} Watering / Phase 2", start_time + (phase_length).hours, with_alarm: true)
      add_event(cal, "#{name} Watering / Phase 3", start_time + (phase_length * 2).hours, with_alarm: true)
      add_event(cal, "#{name} Harvest", start_time + (phase_length * 3).hours, with_alarm: true)
      cal.publish
      send_data cal.to_ical, type: 'text/calendar', disposition: 'attachment', filename: "#{name}.ics"
      # render plain: cal.to_ical # for debugging
    end
  end

  def add_event(calendar, name, start_time, with_alarm: false)
    calendar.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(start_time)
      e.dtend       = Icalendar::Values::DateTime.new(start_time + 30.minutes)
      e.summary     = name
      e.ip_class    = "PRIVATE"
      if with_alarm
        e.alarm do |a|
          a.summary = name
          a.trigger = "-PT1M" # 1 minute before
        end
      end
    end
  end
end
