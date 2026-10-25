# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- Install deps / prep environment: `bin/setup` (idempotent; also preps DB, clears logs/tmp). Add `--skip-server` to avoid launching the dev server, `--reset` to reset the DB.
- Run dev server (Rails only): `bin/rails server`
- Run full test suite: `bundle exec rspec`
- Run a single spec file: `bundle exec rspec spec/path/to/file_spec.rb`
- Run a single test case: `bundle exec rspec spec/path/to/file_spec.rb:LINE`
- Run tests with coverage (SimpleCov, output in `coverage/`): `COVERAGE=1 bundle exec rspec`
- Lint (RuboCop, rubocop-rails-omakase style): `bin/rubocop`
- Security scan (Brakeman): `bin/brakeman`
- Importmap JS dependency audit: `bin/importmap audit`
- DB prepare/migrate: `bin/rails db:prepare` / `bin/rails db:migrate`

There is no hosted CI (no `.github/workflows/`, no CircleCI/GitLab config). `bin/ci` (backed by `config/ci.rb`, Rails 8's built-in CI runner) exists as a local convenience script, but **its test steps (`bin/rails test`, `bin/rails test:system`) are stale Minitest boilerplate that silently no-op** — this project has no `test/` directory and uses RSpec exclusively. Always verify changes with `bundle exec rspec`, not `bin/ci`, and pair it with `bin/rubocop` / `bin/brakeman` for style/security.

System specs (`spec/system/`) use Capybara with `driven_by(:rack_test)` only — no JS-capable driver is configured, so they can't exercise Stimulus/Turbo behavior.

Do not stage or commit to git unless explicitly requested.

## Architecture

Rails 8.1 monolith (app module `SotaLore`, Ruby 4.0.9) for *SotA Lore* (<www.sotalore.com>), a community item/recipe/crafting database for the game Shroud of the Avatar. Hotwire (Turbo + Stimulus) + Importmap (no Node/webpack build, no `package.json`), Propshaft assets, Tailwind CSS, PostgreSQL, RSpec.

**Views are mid-migration from Haml to Phlex.** Most templates are classic `app/views/**/*.html.haml`, implicitly rendered by action name. A growing subset are Phlex view classes at `app/views/**/*.rb`, namespaced under `Views::` and rendered explicitly (e.g. `render Views::Home::LunarRifts.new`). This is wired in `config/initializers/phlex.rb`, which autoloads `app/views` and `app/components` under custom `Views`/`Components` namespaces (`app/views/base.rb`, `app/components/base.rb`). Reusable Phlex components (icons, tiles) live in `app/components/`.

**Forms are plain-Ruby objects, not ActiveModel-backed AR forms.** `app/forms/` holds form objects (`ApplicationForm`, `RecipeForm`, `PasswordResetForm`) decoupled from ActiveRecord, paired with custom `FormBuilder` subclasses in `app/form_builders/` (`sl_form_builder.rb`, `adm_form_builder.rb`, `basic_form_builder.rb`) used app-wide instead of Rails' default builder.

**No `app/services/` — domain logic is POROs living directly in `app/models/`** alongside ActiveRecord models, with no naming convention distinguishing them (must open the file to tell). Examples: `work_list.rb` (recursive crafting-requirement computation for a `Recipe`), `revision_recorder.rb` (diffs model changes into `Comment` revision records), `astronomy.rb`/`clock.rb`/`constellations.rb`/`sota.rb` (in-game time/astronomy simulation).

**Authentication is hand-rolled, migrated off Devise** (a Devise migration file remains, but the gem is gone). Centered on `Current` (`app/models/current.rb`, an `ActiveSupport::CurrentAttributes` singleton holding `user`/`user_key`/`ip_address`/etc. for the request) and `NullUser` (null-object pattern — `current_user` is never `nil`, check `.null?`/`.not_null?`). `app/controllers/concerns/authentication_support.rb` sets `Current` from signed permanent cookies (`cookies.signed.permanent[:current_user_id]`) each request, and contains a temporary `find_past_devise_user` shim that upgrades legacy Devise/Warden sessions on the fly — a live migration in progress, not dead code. OAuth (Discord only) goes through `omniauth-discord`.

**Authorization via Pundit is enforced globally.** `ApplicationController` (`app/controllers/application_controller.rb`) runs `after_action :verify_authorized` for every request — any new controller action must call a Pundit policy (`authorize`/`policy_scope`) or explicitly `skip_after_action :verify_authorized`. Policies live one-per-resource in `app/policies/`, inheriting `ApplicationPolicy`'s role-gated defaults (`has_role?('root')`).

**AI accounts propose; editors decide.** The API (`app/controllers/api/v1/`, token auth via `ApiToken`) lets AI accounts read the data and propose changes (`Proposal`), which editors accept or reject at ADM → Proposals. Each kind of change is a class in `app/models/proposal_changes.rb` that checks, describes and applies it; add one there to make a new kind proposable, and it shows up in `GET /api/v1/proposal_changes`. The project skill `.claude/skills/propose-changes/` tells an agent session how to use the API (the token lives in `~/.config/sotalore/api-token`).

**No background job system.** `app/jobs/` only has the stock `ApplicationJob`; no Sidekiq/Solid Queue/GoodJob/Resque is installed despite Rails-8-generated boilerplate hinting at Solid Queue (`config/puma.rb`'s `plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]` is dead — the gem isn't in the Gemfile). ActiveJob defaults to the in-process `:async` adapter everywhere; mailers use `.deliver_now`, not `.deliver_later`. Action Cable is configured (`redis` adapter) but has no custom channels, so it's effectively unused.

**Storage and images:** ActiveStorage backed by Cloudflare R2 in production via the standard S3 service adapter (`config/storage.yml`'s `cloudflare_r2` service, `aws-sdk-s3`, credentials from `Rails.application.credentials.r2.*`), local disk in dev/test. Image variants use `image_processing` + `ruby-vips` (libvips), which requires native deps installed via `Aptfile` on Heroku's buildpacks — the team has flip-flopped between vips and ImageMagick/MiniMagick a few times in git history before settling on vips.

**Deployment is on Heroku** (`Procfile`, with a `release` phase that runs `db:migrate`, and `Aptfile` for native deps). `lib/tasks/heroku.rake` has manual `heroku:push`/`heroku:migrate`/etc. tasks. `ApplicationController#redirect_herokuapp_url` permanently redirects any host other than `www.sotalore.com` to it. DigitalOcean was evaluated and abandoned (`DO-MOVE.md`, historical notes only). There's no Dockerfile for the app itself — `docker-compose.yml` only runs a local Postgres container for dev.

**The game plugin and its exports.** `sl-lua/` is the in-game Lua plugin (SotaLore) that exports data from *Shroud of the Avatar*: recipe exports today, item catalogs and per-scene finds next. A separate agent works on it, only within `sl-lua/`. **`sl-lua/EXPORT-FORMAT.md` is the contract between the plugin and this app**: the plugin agent owns it and updates it whenever an export changes. Read it before working on anything that imports game data (`RecipeImport`, `GameRecipe`, `GameGroup` and the `Adm::RecipeImports` pages); `git log -p sl-lua/EXPORT-FORMAT.md` shows what changed since the importer last caught up. Talking the other way, **`sl-lua/FROM-THE-APP.md`** is written by the app side for the plugin agent: how the site uses the exports and the site's data model (and requests R1 to R6, from before issues). From the app side, it's the only file in `sl-lua/` to edit; keep its data model in step when models change. **New requests for the plugin are GitHub issues labelled `plugin`** (see "Tracking work" below), not edits to the plugin or its format doc. If you're the plugin agent, read `FROM-THE-APP.md` for how the site's data fits together and the open `plugin` issues for what's wanted, and answer them in the issue. When an answer changes an export, update `EXPORT-FORMAT.md` in the same PR (the importer reads exactly what it describes, so keep it accurate and flag breaking changes in it); when nothing changes, a comment on the issue is the whole answer.

**Value, merchant price and market price are three different numbers.** Use the game's words. *Value* (`items.value`) is what an NPC merchant pays you for an item. It's the tooltip's "Value" line, set by item catalog imports, and 0 means "No Value". "Merchant pays" gives a range at or below it, lower for a worn item. The catalog file's own `value` field isn't reliable (see `GameCatalog::Entry#tooltip_value`). *Merchant price* (`items.merchant_price`) is what an NPC merchant sells it for. It's entered by hand, and many items have none because only players sell them. *Market price* (`MarketPrice`) is what players trade it for: each user sets their own, and only they see it. `RecipeCost` works out what a recipe costs a user from these: their market price, else the merchant price, else what making it costs (tools aren't counted). Garlic, for example, has a value of 3, a merchant price of 6, and often a market price of 1.2. Never write a bare "price" for one of them; it was `items.price` until 2026-10-23.

**The site shows the game as it is now, not its history.** Delete recipes, items, aliases and comments that are out of date rather than keeping them; nobody needs what something used to be called or how an old recipe looked. The exception is recent change comments (revisions), which tell players something just changed in the game. Archetypes are the main case: the game has one recipe ("Two-handed Sword") whose choices decide what you get, so the site keeps no recipe or item per combination ("Copper Two-Handed Sword with Copper Hilt"); `ArchetypeOptions` works the choices out and `ArchetypeCleanup` finds old per-combination recipes to delete.

**Turbo prefetch stays off.** `<body>` carries `turbo_prefetch: "false"` in all three layouts, because the site runs on the smallest Heroku dyno and prefetch adds a request for every hovered link. Keep it off; prefer changes that cut requests or page weight.

**A "+N" item name doesn't mean crafted.** Some creatures drop +N weapons as loot (elves drop "Elven Woodwind Bow +1"), and those are items in their own right. Only the tooltip's "Crafted by" (the item catalog's `details.crafted`) says an item is crafted; see `GameCatalog::Entry#crafted?`. Stripping "+N" is fine only for an item already known to be crafted, to compare it with its base item.

**Domain-specific ETL:** `lib/tasks/data66.rake` and `lib/tasks/parse.rake` are bespoke rake tasks that import game crafting/recipe/item data from CSV/parsed sources into `Recipe`/`Item` records — not generic infrastructure, specific to this app's content pipeline.

## Tracking work

Work and conversation live in **GitHub issues** on `sotalore/sotalore` (with `gh`); the repo's docs hold what must be versioned with the code (`EXPORT-FORMAT.md`, the data model, this file).

- **A plan with several steps gets a tracking issue** (label `tracking`, pinned while it's active) whose sub-issues are the steps. It's where Darren looks to see where things stand, so keep its checklist current. The current one is sotalore/sotalore#250.
- **Before starting work, find or open its issue.** Work that's part of a plan is a sub-issue of the tracking issue (`gh api -X POST repos/sotalore/sotalore/issues/<tracking>/sub_issues -F sub_issue_id=<issue id>`, where the id is `gh api repos/sotalore/sotalore/issues/<n> -q .id`).
- **PRs say "Closes #N"** for the issue they finish. When a step lands, tick it on the tracking issue and add a one-line comment linking the PR.
- **Labels say whose side it is:** `app` (this Rails app) or `plugin` (`sl-lua/`), plus `bug` or `enhancement`. Requests from the app to the plugin are `plugin` issues, answered in the issue; `EXPORT-FORMAT.md` changes only when an export does.
- **The repo is public, so issues are too.** Never put credentials, tokens or anything about users in one.
- `gh` is signed in as Darren, so end issues and comments you write with `_Opened by Claude Code for @darrenboyd._` (or "Comment by Claude Code") so it's clear who wrote them.
