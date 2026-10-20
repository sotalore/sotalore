import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import Mousetrap from "mousetrap"

export default class extends Controller {

    connect() {
        Mousetrap.bind('g n i', function() { Turbo.visit("/items/new") });
        Mousetrap.bind('g n r', function() { Turbo.visit("/recipes/new") });
        Mousetrap.bind('/', function() {
            document.getElementById('global-search').focus();
            return false;
        })
    }

}
