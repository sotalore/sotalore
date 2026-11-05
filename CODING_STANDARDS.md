# Coding standards

The rules code in this repository follows. Code review checks every change against them. RuboCop, Brakeman and the specs cover the rest.

## Hotwire and Turbo

- Anything that changes data is a form button (`button_to`, the button helpers), never a link, and never a link with `data-turbo-method`.
- Markup a Stimulus controller shows or hides is rendered in the state the controller expects. A form that returns to its own page refreshes it by morphing, which puts back the server's markup, and the controller doesn't connect again to fix it.
- One user action starts at most one Turbo visit. A controller that visits a page doesn't also let a link's own click go through.
- Links to file downloads opt out of Turbo.
- Turbo prefetch stays off in every layout: the site runs on the smallest Heroku dyno, and prefetch adds a request for every hovered link.

## Game data and imports

- A file's version is checked when it's uploaded, not when a stored import is read, so older imports can still be viewed and deleted.
- Numbers from the game are rounded to the precision the site stores before they're compared or saved, so float noise doesn't count as a change.

## The site's data model

- Never write a bare "price". An item has a value (what a merchant pays), a merchant price (what a merchant sells it for) and market prices (what players trade it for), and code and text name the one they mean.
- A "+N" item name doesn't mean crafted. Only the tooltip's "Crafted by" does (`GameCatalog::Entry#crafted?`).
- Out-of-date recipes, items, aliases and comments are deleted, not kept or hidden. Recent revisions are the exception.
- `current_user` is never nil: check `.null?` or `.not_null?`.

## Maintaining this file

A rule belongs here only when it came from a review finding the author fixed, a fix commit, a cleanup that removed a pattern across the codebase, or a written-up solution, and no check already covers it. State each as a condition that stays true without naming volatile numbers or symbols, and group rules by area. When a change sets a new rule or retires one, update this file in the same change.
