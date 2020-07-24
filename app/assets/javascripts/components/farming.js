(function(global, $) {

  function setupFarmingPlan(idx, e) {
    var $plan = $(e);
    $plan.find('.plantingLocation').on('change', function () { fillTimes($plan); });
    $plan.find('.seedType').on('change', function () { fillTimes($plan); });
    fillTimes($plan);
  }

  function fillTimes($plan) {
    var startTime = moment();
    var baseTime = parseInt($plan.find('.seedType').val(), 10);
    var locationAdjust = parseFloat($plan.find('.plantingLocation').val());
    baseTime = baseTime * locationAdjust;

    $plan.find(".startTime").html(describeTime(startTime));
    $plan.find(".segment0").html(describeTime(startTime));
    $plan.find(".segment1").html(describeTime(startTime.add(baseTime, "hours")));
    $plan.find(".segment2").html(describeTime(startTime.add(baseTime, "hours")));
    $plan.find(".endTime").html(describeTime(startTime.add(baseTime, "hours")));
  }

  function describeTime(time) {
    if (time.diff(moment(), 'days') >= 6) {
      return time.format('LLLL');
    } else {
      return time.calendar();
    }
  }

  var Farming = (function () {

    return {
      pageLoad: function() {
        $('.FarmingPlan').each(setupFarmingPlan);
      }
    };
  })();

  global.Farming = Farming;

})(SotaLore, jQuery);
