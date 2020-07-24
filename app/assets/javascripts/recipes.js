(function(global, $) {

  var Recipes = (function () {

    function searchItemComplete(query, suggestions) {
      var container = $(this).closest('.recipe-item-container');
      if (suggestions.length === 0) {
        container.find('.recipe-item-id').val('');
      }
    }

    function selectItem(suggestion) {
      var container = $(this).closest('.recipe-item-container');
      container.find('.recipe-item-id').val(suggestion.data);
    }

    return {
      pageLoad: function() {
        $("input.recipe-item-lookup").autocomplete({
          serviceUrl: '/search/items',
          triggerSelectOnValidInput: false,
          noCache: true,
          onSearchComplete: searchItemComplete,
          onSelect: selectItem
        });

      }

    };

  })();

  global.Recipes = Recipes;

})(SotaLore, jQuery);
