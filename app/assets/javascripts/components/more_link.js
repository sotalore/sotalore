(function(global, $) {

  function handleMoreClick(e) {
    var self = $(this);
    var id = self.data('into');
    if (id) {
      var target = $("#" + id);
      if (target.html().length == 0) {
        self.addClass('MoreLink--filled');
        return true;
      } else {
        target.toggle();
        self.toggleClass('MoreLink--filled');
        e.preventDefault();
        e.stopImmediatePropagation();
        return false;
      }
    } else {
      self.addClass('MoreLink--filled');
      return true;
    }
  }

  var MoreLink = (function () {

    return {
      pageLoad: function() {
        $(document).on("ajax:before", "a.MoreLink", handleMoreClick);
      }

    };

  })();

  global.MoreLink = MoreLink;

})(SotaLore, jQuery);
