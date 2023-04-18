# frozen_string_literal: true

class Constellations

  ORBITAL_PERIOD = Clock::NB_YEAR

  TIME_PER_CONSTELLATION = Clock::NB_YEAR / 12

  # assumes January Chalice is north
  ALL = {
    ankh:    { offset: 356, virtue: 'Spirituality', city: 'Fortus End' },
    crook:   { offset: 26,  virtue: 'Humility',     city: 'Eastmarch' },
    book:    { offset: 56,  virtue: 'Truth',        city: 'Aerie' },
    candle:  { offset: 86,  virtue: 'Love',         city: 'Ardoris' },
    bell:    { offset: 116, virtue: 'Courage',      city: 'Resolute' },
    ethos:   { offset: 146, virtue: '',             city: '' },
    hand:    { offset: 176, virtue: 'Honesty',      city: 'Etceter' },
    heart:   { offset: 206, virtue: 'Compassion',   city: 'Brookside' },
    sword:   { offset: 236, virtue: 'Valor',        city: 'Point West' },
    scales:  { offset: 266, virtue: 'Justice',      city: 'Jaanaford' },
    tear:    { offset: 296, virtue: 'Sacrifice',    city: 'Northwood' },
    chalice: { offset: 326, virtue: 'Honor',        city: 'Kiln' },
  }

end
