# frozen_string_literal: true

class Constellations

  ORBITAL_PERIOD = 6 * Clock::NB_MONTH

  # assumes January Chalice is north
  ALL = {
    chalice: { offset: 330,   virtue: 'Honor',        city: 'Kiln' },
    tear:    { offset: 300, virtue: 'Sacrifice',    city: 'Northwood' },
    scales:  { offset: 270, virtue: 'Justice',      city: 'Jaanaford' },
    sword:   { offset: 240, virtue: 'Valor',        city: 'Point West' },
    heart:   { offset: 210, virtue: 'Compassion',   city: 'Brookside' },
    hand:    { offset: 180, virtue: 'Honesty',      city: 'Etceter' },
    ethos:   { offset: 150, virtue: '',             city: '' },
    bell:    { offset: 120, virtue: 'Courage',      city: 'Resolute' },
    candle:  { offset: 90, virtue: 'Love',         city: 'Ardoris' },
    book:    { offset: 60,  virtue: 'Truth',        city: 'Aerie' },
    crook:   { offset: 30,  virtue: 'Humility',     city: 'Eastmarch' },
    ankh:    { offset: 0,  virtue: 'Spirituality', city: 'Fortus End' },
  }

end
