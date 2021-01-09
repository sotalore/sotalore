
export default class {

  pageLoad() {
    $('.FarmingPlan').each((idx, e) => { this.setupFarmingPlan(e) });
  }

  setupFarmingPlan(e) {
    var $plan = $(e);
    $plan.find('.plantingLocation').on('change', (e) => this.fillTimes($plan));
    $plan.find('.seedType').on('change', (e) => this.fillTimes($plan));
    this.fillTimes($plan);
  }

  fillTimes($plan) {
    var startTime = moment();
    var baseTime = parseInt($plan.find('.seedType').val(), 10);
    var locationAdjust = parseFloat($plan.find('.plantingLocation').val());
    baseTime = baseTime * locationAdjust;

    $plan.find(".startTime").html(this.describeTime(startTime));
    $plan.find(".segment0").html(this.describeTime(startTime));
    $plan.find(".segment1").html(this.describeTime(startTime.add(baseTime, "hours")));
    $plan.find(".segment2").html(this.describeTime(startTime.add(baseTime, "hours")));
    $plan.find(".endTime").html(this.describeTime(startTime.add(baseTime, "hours")));
  }

  describeTime(time) {
    if (time.diff(moment(), 'days') >= 6) {
      return time.format('LLLL');
    } else {
      return time.calendar();
    }
  }

}
