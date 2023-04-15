# frozen_string_literal: true

class Constellations

  ORBITAL_PERIOD = Clock::NB_YEAR

  TIME_PER_CONSTELLATION = Clock::NB_YEAR / 12

  # assumes January Chalice is north
  ALL = {
    ankh:    { offset: 355, virtue: 'Spirituality', city: 'Fortus End' },
    crook:   { offset: 25, virtue: 'Humility',     city: 'Eastmarch' },
    book:    { offset: 55, virtue: 'Truth',        city: 'Aerie' },
    candle:  { offset: 85,  virtue: 'Love',         city: 'Ardoris' },
    bell:    { offset: 115,  virtue: 'Courage',      city: 'Resolute' },
    ethos:   { offset: 145,  virtue: '',             city: '' },
    hand:    { offset: 175, virtue: 'Honesty',      city: 'Etceter' },
    heart:   { offset: 205, virtue: 'Compassion',   city: 'Brookside' },
    sword:   { offset: 235, virtue: 'Valor',        city: 'Point West' },
    scales:  { offset: 265, virtue: 'Justice',      city: 'Jaanaford' },
    tear:    { offset: 295, virtue: 'Sacrifice',    city: 'Northwood' },
    chalice: { offset: 325, virtue: 'Honor',        city: 'Kiln' },
  }

end
