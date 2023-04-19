# frozen_string_literal: true

class Constellations

  ORBITAL_PERIOD = Clock::NB_YEAR

  TIME_PER_CONSTELLATION = Clock::NB_YEAR / 12

  # assumes January Chalice is north
  ALL = {
    ankh:    { offset: 0,   virtue: 'Spirituality', city: 'Fortus End' },
    crook:   { offset: 30,  virtue: 'Humility',     city: 'Eastmarch' },
    book:    { offset: 60,  virtue: 'Truth',        city: 'Aerie' },
    candle:  { offset: 90,  virtue: 'Love',         city: 'Ardoris' },
    bell:    { offset: 120, virtue: 'Courage',      city: 'Resolute' },
    ethos:   { offset: 150, virtue: '',             city: '' },
    hand:    { offset: 180, virtue: 'Honesty',      city: 'Etceter' },
    heart:   { offset: 210, virtue: 'Compassion',   city: 'Brookside' },
    sword:   { offset: 240, virtue: 'Valor',        city: 'Point West' },
    scales:  { offset: 270, virtue: 'Justice',      city: 'Jaanaford' },
    tear:    { offset: 300, virtue: 'Sacrifice',    city: 'Northwood' },
    chalice: { offset: 330, virtue: 'Honor',        city: 'Kiln' },
  }

end
