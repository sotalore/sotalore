# frozen_string_literal: true

class Clock

  NB_MINUTE = 2.5            # seconds
  NB_HOUR   = 60 * NB_MINUTE # 1/24th of a real hour
  NB_DAY    = 24 * NB_HOUR   # exactly 1 real hour
  NB_MONTH  = 28 * NB_DAY    # 28 real hours
  NB_YEAR   = 12 * NB_MONTH  # 336 real hours or 14 real days

  # This is not year zero, but year 400, when the avatars arrived (again)
  EPOCH = Time.zone.parse('January 1, 2013 00:00:00 -0000')
  BEGINNING_OF_PC = EPOCH - (400 * NB_YEAR)

  MONTHS = %w(Janus Februa Marse Apru Maia Juno Julius Augus Septembre Octobre Novembre Decembre)

  class << self

    def real_seconds_since_beginning(time=nil)
      time ||= Time.zone.now
      (time - BEGINNING_OF_PC).to_i
    end

    def time_to_nbt(time=nil)
      year, month, day, hour, minute = time_to_nbt_date_parts(time)
      "#{MONTHS[month - 1]} #{day}, #{year}PC #{"%02d" % hour}:#{"%02d" % minute}"
    end

    def time_to_nbt_date_parts(time=nil)
      rt_seconds = real_seconds_since_beginning(time)

      minute = ((rt_seconds % NB_HOUR) / NB_MINUTE).floor
      hour   = ((rt_seconds % NB_DAY) / NB_HOUR).floor
      day    = ((rt_seconds % NB_MONTH) / NB_DAY).floor + 1
      month  = ((rt_seconds % NB_YEAR) / NB_MONTH).floor + 1
      year   = (rt_seconds / NB_YEAR).floor

      [ year, month, day, hour, minute ]
    end

  end
end
