export default class Astronomy {

  static nbMinute = 2.5 // seconds
  static nbHour = 60 * Astronomy.nbMinute // 150 seconds ... 1 game-hour is 1/24th of an hour
  static nbDay = 24 * Astronomy.nbHour // 1 hour
  static nbMonth = 28 * Astronomy.nbDay // 28 hours
  static nbYear = 12 * Astronomy.nbMonth // 336 hours == 14 days

  // This is not year zero, but year 400, when the avatars arrived (again)
  static epoch = Math.floor(new Date("January 1, 2013 00:00:00 -0000").getTime() / 1000)
  static beginningOfPC = Astronomy.epoch - (400 * Astronomy.nbYear)

  static constellationOrbit = 6 * Astronomy.nbMonth

  /*
   * Returns the area of the sky the constellation "covers".
   * The value is [ leading-edge, trailing-edge ] in degrees.
   *
   * The constellations rise in the west and set in the east, travelling
   * in a clockwise direction. They all move at the same speed.
   *
   */
  static positionOfConstellation(offset) {
    let position = this.portionOfOrbitComplete(Astronomy.constellationOrbit)
    position *= 360
    position += offset
    if (position > 359) {
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
  static positionOfPlanet(orbitalPeriod) {
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
  static portionOfOrbitComplete(orbitalPeriod) {
    let now = new Date()
    let seconds = (now.getTime() / 1000) - Astronomy.beginningOfPC
    let remainder = seconds % orbitalPeriod
    return remainder / orbitalPeriod
  }
}
