
var Mousetrap = require('mousetrap')

export default function mousetrap_config() {

  Mousetrap.bind('g n i', function() {window.location = "/items/new"; });
  Mousetrap.bind('g n r', function() {window.location = "/recipes/new"; });
  Mousetrap.bind('/', function() {
    document.getElementById('global-search').focus();
    return false;
  })

}