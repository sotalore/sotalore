# frozen_string_literal: true

require "icalendar/tzinfo"

class FarmingCalendarsController < ApplicationController
  skip_after_action :verify_authorized

  def show
    Time.use_zone("UTC") do
      start_time = parse_start_time(params[:start])
      base_time = parse_integer(params[:seedTime])
      location_factor = parse_float(params[:locationFactor])

      if start_time.nil? || base_time.nil? || location_factor.nil?
        redirect_to farming_path, alert: "That calendar link is missing some information, please try downloading it again."
        return
      end

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

  private

  def parse_start_time(value)
    return nil if value.blank?
    Time.zone.parse(value)&.utc
  rescue ArgumentError, TypeError
    nil
  end

  def parse_integer(value)
    return nil if value.blank?
    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end

  def parse_float(value)
    return nil if value.blank?
    Float(value)
  rescue ArgumentError, TypeError
    nil
  end
end
