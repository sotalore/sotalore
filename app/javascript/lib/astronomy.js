export default class Astronomy {

  static nbMinute = 2.5 // seconds
  static nbHour = 60 * Astronomy.nbMinute // 150 seconds ... 1 game-hour is 1/24th of an hour
  static nbDay = 24 * Astronomy.nbHour // 1 hour
  static nbMonth = 28 * Astronomy.nbDay // 28 hours
  static nbYear = 12 * Astronomy.nbMonth // 336 hours == 14 days

  // This is not year zero, but year 400, when the avatars arrived (again)
  static epoch = Math.floor(new Date("January 1, 2013 00:00:00 -0000").getTime() / 1000)
  static beginningOfPC = Astronomy.epoch - (400 * Astronomy.nbYear)

  static constellations = [
    { symbol: 'Ankh',     offset: 356, virtue: 'Spirituality', city: 'Fortus End' },
    { symbol: 'Crook',    offset: 26,  virtue: 'Humility',     city: 'Eastmarch' },
    { symbol: 'Book',     offset: 56,  virtue: 'Truth',        city: 'Aerie' },
    { symbol: 'Candle',   offset: 86,  virtue: 'Love',         city: 'Ardoris' },
    { symbol: 'Bell',     offset: 116, virtue: 'Courage',      city: 'Resolute' },
    { symbol: 'Ethos',    offset: 146, virtue: '',             city: '' },
    { symbol: 'Hand',     offset: 176, virtue: 'Honesty',      city: 'Etceter' },
    { symbol: 'Heart',    offset: 206, virtue: 'Compassion',   city: 'Brookside' },
    { symbol: 'Sword',    offset: 236, virtue: 'Valor',        city: 'Point West' },
    { symbol: 'Scales',   offset: 266, virtue: 'Justice',      city: 'Jaanaford' },
    { symbol: 'Tear',     offset: 296, virtue: 'Sacrifice',    city: 'Northwood' },
    { symbol: 'Chalice',  offset: 326, virtue: 'Honor',        city: 'Kiln' },
  ]

  static constellationOrbit = Astronomy.nbYear

  /*
   * Return the current position of every constellation
   */
  currentConstellations() {
    let liveData = []
    for (const constellation of Astronomy.constellations) {
      liveData.push({
        position: this.positionOfConstellation(constellation.offset),
        symbol: constellation.symbol,
        virtue: constellation.virtue,
        city: constellation.city,
      })
    }
    return liveData
  }

  /*
   * Returns the area of the sky the constellation "covers".
   * The value is [ leading-edge, trailing-edge ] in degrees.
   *
   * The constellations rise in the west and set in the east, travelling
   * in a clockwise direction. They all move at the same speed.
   *
   */
  positionOfConstellation(offset) {
    let position = this.portionOfOrbitComplete(Astronomy.constellationOrbit)
    position = 360 - (position * 360)
    position += offset
    if (position >= 360) {
      position -= 360
    }

    let other_edge = position + 30
    if (other_edge > 359) {
      other_edge -= 360
    }

    return [position, other_edge]
  }

  /*
   * Returns the position of the planet in its orbit, in degrees.
   * 0° is the point where the planet is at its highest point in
   * the northern sky.  90° is on the eastern horizon.
   *
   * The planets rise in the east and set in the west, travelling
   * in a counter-clockwise direction.
   *
   */
  positionOfPlanet(orbitalPeriod) {
    var position = this.portionOfOrbitComplete(orbitalPeriod)
    position = 360 - (position * 360)
    if (position === 360) {
      position = 0
    }
    return position
  }

  /*
   * Returns a number between 0 and 1, representing the percentage of the
   * orbit that has been completed.
   */
  portionOfOrbitComplete(orbitalPeriod) {
    let now = new Date()
    let seconds = (now.getTime() / 1000) - Astronomy.beginningOfPC
    let remainder = seconds % orbitalPeriod
    return remainder / orbitalPeriod
  }

  nextConstellation(currentSymbol) {
    const current = Astronomy.constellations.find(c => c.symbol === currentSymbol)
    const index = Astronomy.constellations.indexOf(current)
    const next = Astronomy.constellations[(index - 1) % Astronomy.constellations.length]
    return next
  }

  degreesBetween(from, to) {
    let diff = to - from
    if (diff < 0) {
      diff += 360
    }
    return diff
  }

  isInArc(position, leading, trailing) {
    if (leading > trailing) {
      // The arc is crossing the 0°/360° meridian
      return (position >= leading || position <= trailing)
    } else {
      return (position >= leading && position <= trailing)
    }
  }

  timeToTravel(position, target, period) {
    if (position === target) {
      return 0
    }

    // adjust, if the target is behind us
    if (position < target) {
      position += 360
    }
    const degrees = position - target

    let velocity = 360.0 / period

    return degrees / velocity
  }

}
