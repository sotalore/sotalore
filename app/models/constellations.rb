# frozen_string_literal: true

class Constellations

  ORBITAL_PERIOD = 6 * Clock::NB_MONTH

  # assumes January Chalice is north
  ALL = {
    chalice: { offset: 0 },
    tear: { offset: 330 },
    scales: { offset: 300 },
    sword: { offset: 270 },
    heart: { offset: 240 },
    hand: { offset: 210 },
    ethos: { offset: 180 },
    bell: { offset: 150 },
    candle: { offset: 120 },
    book: { offset: 90 },
    crook: { offset: 60 },
    ankh: { offset: 30 },
  }

end