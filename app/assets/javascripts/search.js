(function(global, $) {

  var Search = (function () {

    function selectItem(suggestion) {
      window.location = suggestion.data;
    }

    function beforeRender(container, suggestions) {
      console.log(container);
      container.addClass('global-search');
    }

    return {
      pageLoad: function() {
        $("input#global-search").autocomplete({
          serviceUrl: '/search.json',
          delay: 300,
          width: 400,
          paramName: 'q',
          noCache: true,
          onSelect: selectItem,
          beforeRender: beforeRender,
          triggerSelectOnValidInput: false,
          minChars: 2
        });
      }

    };

  })();

  global.Search = Search;

})(SotaLore, jQuery);
