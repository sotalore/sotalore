(function(global, $) {

  Mousetrap.bind('g n i', function() {window.location = "/items/new"; });
  Mousetrap.bind('g n r', function() {window.location = "/recipes/new"; });
  Mousetrap.bind('/', function() {
    $('#global-search').focus();
    return false;
  });

})(SotaLore, jQuery);
