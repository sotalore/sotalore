# frozen_string_literal: true

class Constellations

  ORBITAL_PERIOD = Clock::NB_YEAR

  TIME_PER_CONSTELLATION = Clock::NB_YEAR / 12

  # assumes January Chalice is north
  ALL = {
    chalice: { offset: 150, virtue: 'Honor',        city: 'Kiln' },
    tear:    { offset: 120, virtue: 'Sacrifice',    city: 'Northwood' },
    scales:  { offset: 90, virtue: 'Justice',      city: 'Jaanaford' },
    sword:   { offset: 60, virtue: 'Valor',        city: 'Point West' },
    heart:   { offset: 30, virtue: 'Compassion',   city: 'Brookside' },
    hand:    { offset: 0, virtue: 'Honesty',      city: 'Etceter' },
    ethos:   { offset: 330,  virtue: '',             city: '' },
    bell:    { offset: 300,  virtue: 'Courage',      city: 'Resolute' },
    candle:  { offset: 270,  virtue: 'Love',         city: 'Ardoris' },
    book:    { offset: 240, virtue: 'Truth',        city: 'Aerie' },
    crook:   { offset: 210, virtue: 'Humility',     city: 'Eastmarch' },
    ankh:    { offset: 180, virtue: 'Spirituality', city: 'Fortus End' },
  }

end
