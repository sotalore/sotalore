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

Rails 8.1 monolith (app module `SotaLore`, Ruby 4.0.5) for *SotA Lore* (<www.sotalore.com>), a community item/recipe/crafting database for the game Shroud of the Avatar. Hotwire (Turbo + Stimulus) + Importmap (no Node/webpack build, no `package.json`), Propshaft assets, Tailwind CSS, PostgreSQL, RSpec.

**Views are mid-migration from Haml to Phlex.** Most templates are classic `app/views/**/*.html.haml`, implicitly rendered by action name. A growing subset are Phlex view classes at `app/views/**/*.rb`, namespaced under `Views::` and rendered explicitly (e.g. `render Views::Home::LunarRifts.new`). This is wired in `config/initializers/phlex.rb`, which autoloads `app/views` and `app/components` under custom `Views`/`Components` namespaces (`app/views/base.rb`, `app/components/base.rb`). Reusable Phlex components (icons, tiles) live in `app/components/`.

**Forms are plain-Ruby objects, not ActiveModel-backed AR forms.** `app/forms/` holds form objects (`ApplicationForm`, `RecipeForm`, `PasswordResetForm`) decoupled from ActiveRecord, paired with custom `FormBuilder` subclasses in `app/form_builders/` (`sl_form_builder.rb`, `adm_form_builder.rb`, `basic_form_builder.rb`) used app-wide instead of Rails' default builder.

**No `app/services/` — domain logic is POROs living directly in `app/models/`** alongside ActiveRecord models, with no naming convention distinguishing them (must open the file to tell). Examples: `work_list.rb` (recursive crafting-requirement computation for a `Recipe`), `revision_recorder.rb` (diffs model changes into `Comment` revision records), `astronomy.rb`/`clock.rb`/`constellations.rb`/`sota.rb` (in-game time/astronomy simulation).

**Authentication is hand-rolled, migrated off Devise** (a Devise migration file remains, but the gem is gone). Centered on `Current` (`app/models/current.rb`, an `ActiveSupport::CurrentAttributes` singleton holding `user`/`user_key`/`ip_address`/etc. for the request) and `NullUser` (null-object pattern — `current_user` is never `nil`, check `.null?`/`.not_null?`). `app/controllers/concerns/authentication_support.rb` sets `Current` from signed permanent cookies (`cookies.signed.permanent[:current_user_id]`) each request, and contains a temporary `find_past_devise_user` shim that upgrades legacy Devise/Warden sessions on the fly — a live migration in progress, not dead code. OAuth (Discord only) goes through `omniauth-discord`.

**Authorization via Pundit is enforced globally.** `ApplicationController` (`app/controllers/application_controller.rb`) runs `after_action :verify_authorized` for every request — any new controller action must call a Pundit policy (`authorize`/`policy_scope`) or explicitly `skip_after_action :verify_authorized`. Policies live one-per-resource in `app/policies/`, inheriting `ApplicationPolicy`'s role-gated defaults (`has_role?('root')`).

**No background job system.** `app/jobs/` only has the stock `ApplicationJob`; no Sidekiq/Solid Queue/GoodJob/Resque is installed despite Rails-8-generated boilerplate hinting at Solid Queue (`config/puma.rb`'s `plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]` is dead — the gem isn't in the Gemfile). ActiveJob defaults to the in-process `:async` adapter everywhere; mailers use `.deliver_now`, not `.deliver_later`. Action Cable is configured (`redis` adapter) but has no custom channels, so it's effectively unused.

**Storage and images:** ActiveStorage backed by Cloudflare R2 in production via the standard S3 service adapter (`config/storage.yml`'s `cloudflare_r2` service, `aws-sdk-s3`, credentials from `Rails.application.credentials.r2.*`), local disk in dev/test. Image variants use `image_processing` + `ruby-vips` (libvips), which requires native deps installed via `Aptfile` on Heroku-style buildpacks — the team has flip-flopped between vips and ImageMagick/MiniMagick a few times in git history before settling on vips.

**Deployment targets Render.com primarily** (`render.yaml` blueprint + `bin/render-build.sh`, which runs `db:migrate` as part of the build step), with Heroku kept alive in parallel (`Procfile`, `Aptfile`, `lib/tasks/heroku.rake` for manual `heroku:push`/`heroku:migrate`/etc.). `ApplicationController#redirect_herokuapp_url` permanently redirects any host other than `sotalore.onrender.com`/`www.sotalore.com` to the canonical domain. DigitalOcean was evaluated and abandoned (`DO-MOVE.md`, historical notes only). There's no Dockerfile for the app itself — `docker-compose.yml` only runs a local Postgres container for dev.

**Domain-specific ETL:** `lib/tasks/data66.rake` and `lib/tasks/parse.rake` are bespoke rake tasks that import game crafting/recipe/item data from CSV/parsed sources into `Recipe`/`Item` records — not generic infrastructure, specific to this app's content pipeline.
