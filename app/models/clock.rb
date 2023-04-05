class Clock

  # This is not year zero, but year 400, when the avatars arrived (again)
  EPOCH = Time.zone.parse('January 1, 2013 00:00:00 -0000')

  NB_HOUR = (60 * 60) / 24   # 150 seconds ... 1 game-hour is 1/24th of an hour
  NB_MINUTE = NB_HOUR / 60.0 # 2.5 seconds

  NB_DAY = 60 * 60         # 1 game-day is 1 hour
  NB_MONTH = 28 * NB_DAY   # 1 game-month is 28 game-days
  NB_YEAR = 12 * NB_MONTH  # 1 game-year is 12 game-months (14 days)

  MONTHS = %w(Janus Februa Marse Apru Maia Juno Julius Augus Septembre Octobre Novembre Decembre)

  class << self
    def time_to_bst(time)
      seconds = time - EPOCH
      year = (seconds / NB_YEAR).floor
      seconds -= year * NB_YEAR
      year += 400

      month = (seconds / NB_MONTH).floor
      seconds -= month * NB_MONTH

      day = (seconds / NB_DAY).floor + 1

      in_utc = time.utc
      seconds_since_top_of_hour = (in_utc.min * 60) + in_utc.sec

      hour = (seconds_since_top_of_hour / NB_HOUR).floor
      seconds_since_top_of_hour -= hour * NB_HOUR
      minute = (seconds_since_top_of_hour / NB_MINUTE).floor

      "#{MONTHS[month]} #{day}, #{year}PC #{"%02d" % hour}:#{"%02d" % minute}"
    end
  end
end
