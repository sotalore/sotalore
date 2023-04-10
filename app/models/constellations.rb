# frozen_string_literal: true

class Constellations

  ORBITAL_PERIOD = 6 * Clock::NB_MONTH

  # assumes January Chalice is north
  ALL = {
    chalice: { offset: 0,   virtue: 'Honor',        city: 'Kiln' },
    tear:    { offset: 330, virtue: 'Sacrifice',    city: 'Northwood' },
    scales:  { offset: 300, virtue: 'Justice',      city: 'Jaanaford' },
    sword:   { offset: 270, virtue: 'Valor',        city: 'Point West' },
    heart:   { offset: 240, virtue: 'Compassion',   city: 'Brookside' },
    hand:    { offset: 210, virtue: 'Honesty',      city: 'Etceter' },
    ethos:   { offset: 180, virtue: '',             city: '' },
    bell:    { offset: 150, virtue: 'Courage',      city: 'Resolute' },
    candle:  { offset: 120, virtue: 'Love',         city: 'Ardoris' },
    book:    { offset: 90,  virtue: 'Truth',        city: 'Aerie' },
    crook:   { offset: 60,  virtue: 'Humility',     city: 'Eastmarch' },
    ankh:    { offset: 30,  virtue: 'Spirituality', city: 'Fortus End' },
  }

end
