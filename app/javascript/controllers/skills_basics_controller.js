import { Controller } from "stimulus"

export default class extends Controller {

  static targets = [ 'toLevel', 'xpFactor' ]

  connect() {

    let [labels, data] = this.calculateChartData()

    var ctx = document.getElementById('skillBasicsChart')
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          data: data,
          label: "Required XP",
          borderColor: "#3e95cd",
          fill: false
        }]
      }
    })
  }

  setLevel(e) {
    let [labels, data] = this.calculateChartData()

    this.chart.data.labels = labels
    this.chart.data.datasets[0].data = data

    this.chart.update()
  }

  calculateChartData() {
    let maxLevel = this.getMaxLevel()
    let factor = this.getXPFactor()
    let labels = []
    let data = []
    this.xpFactorValue = 1
    for (let i = 1; i <= maxLevel; i++) {
      labels.push(i)
      data.push(this.calculateXPForLevel(i, factor))
    }

    return [ labels, data ]
  }

  getMaxLevel() {
    let level = this.toLevelTarget.value
    level = parseInt(level, 10)
    if (Number.isNaN(level)) {
      return 200
    }
    return level
  }

  getXPFactor() {
    let factor = this.xpFactorTarget.value
    factor = parseFloat(factor)
    if (Number.isNaN(factor)) {
      return 1
    }
    return factor
  }

  calculateXPForLevel(level, factor) {
    level = parseInt(level, 10)
    if (!Number.isInteger(level)) {
      return null
    }

    if (level === 0) {
      return 0
    }
    return (factor * (Math.ceil(((1.099711**(level-1)) - 1) * 100)))
  }

}
