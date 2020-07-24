;
var GravidyLunarRift;

(GravidyLunarRift = function($, window, document, undefined) {

  var single_duration = (8 * 60) + 45;
  var full_cycle = ((8 * 60) + 45) * 8;
  // skew happened somewhere, which is the -40
  epoch = Math.floor(new Date("January 1, 2013 00:00:00 -0000").getTime() / 1000) - 40;
  var refreshTimer;

  function refresh() {
    var e = elapsed();
    GravidyLunarRift.riftTargets.each(function (idx, rift) {
      var el = $(rift);
      var idx = parseInt(el.data("index"), 10);
      var w = where_is(idx, e);
      if (w < 0) {
        el.addClass('active');
        el.find('div').html(minutes_and_seconds(-1 * w));
      } else {
        el.removeClass('active');
        el.find('div').html(minutes_and_seconds(w));
      }
    });
  }

  function startRefreshing() {
    refreshTimer = setInterval(() => {
      refresh();
    }, 1000);
  }

  function stopRefreshing() {
    if (refreshTimer) {
      clearInterval(refreshTimer);
    }
  }

  function elapsed() {
    var now =  Math.floor(new Date().getTime() / 1000);
    return (now - epoch) % full_cycle;
  }

  function where_is(idx, elapsed) {
    var end_time = (idx * single_duration)
    var beg_time = (idx * single_duration) - single_duration

    if (elapsed >= beg_time && elapsed < end_time) {
      // active
      return -(end_time - elapsed)
    } else if (elapsed < beg_time) {
      // in this cycle, but later
      return beg_time - elapsed
    } else {
      // in next cycle
      return full_cycle - elapsed + beg_time
    }
  }

  function minutes_and_seconds(i) {
    var s = i % 60
    var m = Math.floor((i - s) / 60)
    return "" + padded(m) + ":" + padded(s)
  }

  function padded(i) {
    if (i < 10) {
      return "0" + i
    } else {
      return "" + i
    }
  }

  return {
    init: function() {
      GravidyLunarRift.riftTargets = $('.LunarRift .rift');
      refresh();
      startRefreshing();
    }
  }
}(jQuery, window, document));

jQuery(document).ready(GravidyLunarRift.init);