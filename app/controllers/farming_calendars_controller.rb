class FarmingCalendarsController < ApplicationController
  skip_after_action :verify_authorized

  def show
    start_time = Time.parse(params[:start])
    base_time = Integer(params[:seedTime])
    location_factor = Float(params[:locationFactor])
    name = params[:name]
    name = name.gsub(/[^0-9A-Za-z-_ ]/, '')
    name = 'Farm Watering' if name.blank?

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(start_time)
      e.dtend       = Icalendar::Values::DateTime.new(start_time + (base_time).hours)
      e.summary     = "#{name} Phase 1"
      e.ip_class    = "PRIVATE"
    end
    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(start_time + (base_time).hours)
      e.dtend       = Icalendar::Values::DateTime.new(start_time + (base_time * 2).hours)
      e.summary     = "#{name} Phase 2"
      e.ip_class    = "PRIVATE"
      e.alarm do |a|
        a.summary = "#{name} Phase 2"
        a.trigger = "-PT1M" # 1 minute before
      end
    end
    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(start_time + (base_time * 2).hours)
      e.dtend       = Icalendar::Values::DateTime.new(start_time + (base_time * 3).hours)
      e.summary     = "#{name} Phase 3"
      e.ip_class    = "PRIVATE"
      e.alarm do |a|
        a.summary = "#{name} Phase 3"
        a.trigger = "-PT1M" # 1 minute before
      end
    end

    cal.publish
    send_data cal.to_ical, type: 'text/calendar', disposition: 'attachment', filename: "#{name}.ics"
  end
end
