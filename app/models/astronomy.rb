# frozen_string_literal: true

class Astronomy

  # These are in order of distance from Sosaria
  PLANETS = {
    deceit:     { color: 'blue',   cabalist: 'Dolus',   orbital_period: 19, offset: 0 },
    despise:    { color: 'yellow', cabalist: 'Temna',   orbital_period: 17, offset: 0 },
    dastard:    { color: 'red',    cabalist: 'Nefario', orbital_period: 13, offset: 0 },
    injustice:  { color: 'green',  cabalist: 'Nefas',   orbital_period: 11, offset: 0 },
    punishment: { color: 'orange', cabalist: 'Avara',   orbital_period: 3,  offset: 0 },
    dishonor:   { color: 'purple', cabalist: 'Indigno', orbital_period: 2,  offset: 0 },
    carnality:  { color: 'white',  cabalist: 'Corpus',  orbital_period: 23, offset: 0 },
    vanity:     { color: 'black',  cabalist: 'Fastus',  orbital_period: 29, offset: 0 },
  }

  DAEDALUS_ORBITAL_PERIOD = 7

  class << self

    def orbital_period_real_seconds(planet)
      raise ArgumentError, "Unknown planet: #{planet}" unless PLANETS.key?(planet)

      PLANETS[planet][:orbital_period] * Clock::NB_DAY
    end

    def planet_position(planet, time: nil)
      raise ArgumentError, "Unknown planet: #{planet}" unless PLANETS.key?(planet)

      rt_seconds = Clock.real_seconds_since_beginning(time)
      period = orbital_period_real_seconds(planet)
      remainder = (rt_seconds % period)
      position = 360 - ((remainder / period.to_f) * 360)
      position == 360 ? 0 : position
    end

    def time_to(position:, period:, target:, target_period: 0)
      return 0 if position == target

      # adjust, if the target is behind us
      position += 360 if position < target
      # how many degrees do we need to travel?
      degrees = position - target

      velocity = 360.0 / period # degrees per second

      if target_period != 0
        target_velocity = 360.0 / target_period
        velocity -= target_velocity
      end

      degrees / velocity
    end

    def planet_speed
      PLANETS.each do |planet, data|
        period = data[:orbital_period]
        data[:one_degree] = (period * Clock::NB_DAY) / 360.0
      end
    end
  end
end
