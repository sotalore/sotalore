# frozen_string_literal: true

class Constellations

  ORBITAL_PERIOD = Clock::NB_YEAR

  # assumes January Chalice is north
  ALL = {
    chalice: { offset: 195, virtue: 'Honor',        city: 'Kiln' },
    tear:    { offset: 165, virtue: 'Sacrifice',    city: 'Northwood' },
    scales:  { offset: 135, virtue: 'Justice',      city: 'Jaanaford' },
    sword:   { offset: 105, virtue: 'Valor',        city: 'Point West' },
    heart:   { offset: 75, virtue: 'Compassion',   city: 'Brookside' },
    hand:    { offset: 45, virtue: 'Honesty',      city: 'Etceter' },
    ethos:   { offset: 15,  virtue: '',             city: '' },
    bell:    { offset: 345,  virtue: 'Courage',      city: 'Resolute' },
    candle:  { offset: 315,  virtue: 'Love',         city: 'Ardoris' },
    book:    { offset: 285, virtue: 'Truth',        city: 'Aerie' },
    crook:   { offset: 255, virtue: 'Humility',     city: 'Eastmarch' },
    ankh:    { offset: 225, virtue: 'Spirituality', city: 'Fortus End' },
  }

end
