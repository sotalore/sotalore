import { Controller } from "@hotwired/stimulus"
import Mousetrap from "mousetrap"

export default class extends Controller {

    connect() {
        Mousetrap.bind('g n i', function() {window.location = "/items/new"; });
        Mousetrap.bind('g n r', function() {window.location = "/recipes/new"; });
        Mousetrap.bind('/', function() {
            document.getElementById('global-search').focus();
            return false;
        })
    }

}
